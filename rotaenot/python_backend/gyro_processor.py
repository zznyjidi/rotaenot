"""
Gyroscope/Accelerometer Processor for Rotaenot
Handles rotation input processing and smoothing
"""

import math
from typing import Tuple, Optional, List
from dataclasses import dataclass
import numpy as np
from collections import deque


@dataclass
class RotationData:
    """Data structure for rotation information"""
    angle: float  # Current angle in degrees
    angular_velocity: float  # Degrees per second
    angular_acceleration: float  # Degrees per second squared
    timestamp: float  # Time in seconds


class GyroProcessor:
    """Process gyroscope/accelerometer data for rotation control"""

    def __init__(self, smoothing_factor: float = 0.15,
                 dead_zone: float = 2.0):
        """
        Initialize the gyro processor

        Args:
            smoothing_factor: Smoothing factor for rotation (0-1)
            dead_zone: Minimum rotation angle to register (degrees)
        """
        self.smoothing_factor = smoothing_factor
        self.dead_zone = dead_zone
        self.calibration_offset = 0.0
        self.current_angle = 0.0
        self.previous_angle = 0.0
        self.angular_velocity = 0.0
        self.previous_timestamp = None

        # History for smoothing
        self.angle_history = deque(maxlen=10)
        self.velocity_history = deque(maxlen=5)

    def calibrate(self, initial_angle: float = 0.0):
        """
        Calibrate the sensor with initial position

        Args:
            initial_angle: Initial angle to set as zero point
        """
        self.calibration_offset = initial_angle
        self.current_angle = 0.0
        self.previous_angle = 0.0
        self.angular_velocity = 0.0
        self.angle_history.clear()
        self.velocity_history.clear()

    def process_gyro_data(self, x: float, y: float, z: float,
                         timestamp: float) -> RotationData:
        """
        Process raw gyroscope data

        Args:
            x, y, z: Gyroscope readings (rad/s)
            timestamp: Current timestamp in seconds

        Returns:
            Processed RotationData
        """
        # Convert to degrees per second
        angular_velocity_raw = math.degrees(z)  # Using Z-axis for rotation

        # Apply dead zone
        if abs(angular_velocity_raw) < self.dead_zone:
            angular_velocity_raw = 0

        # Calculate time delta
        if self.previous_timestamp is None:
            dt = 0.016  # Assume 60 FPS initially
        else:
            dt = timestamp - self.previous_timestamp

        # Integrate to get angle change
        angle_change = angular_velocity_raw * dt

        # Update current angle
        self.current_angle += angle_change

        # Apply smoothing
        self.angle_history.append(self.current_angle)
        smoothed_angle = self._apply_smoothing(list(self.angle_history))

        # Calculate angular acceleration
        if len(self.velocity_history) > 0:
            angular_acceleration = (angular_velocity_raw - self.velocity_history[-1]) / dt
        else:
            angular_acceleration = 0

        self.velocity_history.append(angular_velocity_raw)

        # Update state
        self.previous_angle = smoothed_angle
        self.previous_timestamp = timestamp
        self.angular_velocity = angular_velocity_raw

        return RotationData(
            angle=smoothed_angle % 360,  # Keep angle in 0-360 range
            angular_velocity=angular_velocity_raw,
            angular_acceleration=angular_acceleration,
            timestamp=timestamp
        )

    def process_accelerometer_data(self, x: float, y: float,
                                 timestamp: float) -> RotationData:
        """
        Process accelerometer data for tilt-based rotation

        Args:
            x, y: Accelerometer readings (m/s²)
            timestamp: Current timestamp in seconds

        Returns:
            Processed RotationData
        """
        # Calculate tilt angle from accelerometer
        angle_raw = math.degrees(math.atan2(y, x))

        # Normalize to 0-360 range
        angle_raw = (angle_raw + 360) % 360

        # Apply calibration offset
        angle_calibrated = (angle_raw - self.calibration_offset) % 360

        # Apply dead zone
        angle_diff = self._angle_difference(angle_calibrated, self.current_angle)
        if abs(angle_diff) < self.dead_zone:
            angle_calibrated = self.current_angle

        # Calculate angular velocity
        if self.previous_timestamp is not None:
            dt = timestamp - self.previous_timestamp
            angular_velocity = angle_diff / dt if dt > 0 else 0
        else:
            angular_velocity = 0
            dt = 0.016

        # Apply smoothing
        self.angle_history.append(angle_calibrated)
        smoothed_angle = self._apply_smoothing(list(self.angle_history))

        # Calculate angular acceleration
        if len(self.velocity_history) > 0:
            angular_acceleration = (angular_velocity - self.velocity_history[-1]) / dt
        else:
            angular_acceleration = 0

        self.velocity_history.append(angular_velocity)

        # Update state
        self.current_angle = smoothed_angle
        self.previous_angle = smoothed_angle
        self.previous_timestamp = timestamp
        self.angular_velocity = angular_velocity

        return RotationData(
            angle=smoothed_angle,
            angular_velocity=angular_velocity,
            angular_acceleration=angular_acceleration,
            timestamp=timestamp
        )

    def simulate_rotation(self, target_angle: float,
                        timestamp: float) -> RotationData:
        """
        Simulate smooth rotation (for mouse/keyboard testing)

        Args:
            target_angle: Target angle to rotate to
            timestamp: Current timestamp

        Returns:
            Simulated RotationData
        """
        # Calculate shortest rotation path
        angle_diff = self._angle_difference(target_angle, self.current_angle)

        # Apply smoothing for realistic movement
        smoothed_diff = angle_diff * self.smoothing_factor
        new_angle = (self.current_angle + smoothed_diff) % 360

        # Calculate angular velocity
        if self.previous_timestamp is not None:
            dt = timestamp - self.previous_timestamp
            angular_velocity = smoothed_diff / dt if dt > 0 else 0
        else:
            angular_velocity = 0
            dt = 0.016

        # Calculate angular acceleration
        if len(self.velocity_history) > 0:
            angular_acceleration = (angular_velocity - self.velocity_history[-1]) / dt
        else:
            angular_acceleration = 0

        self.velocity_history.append(angular_velocity)

        # Update state
        self.current_angle = new_angle
        self.previous_timestamp = timestamp
        self.angular_velocity = angular_velocity

        return RotationData(
            angle=new_angle,
            angular_velocity=angular_velocity,
            angular_acceleration=angular_acceleration,
            timestamp=timestamp
        )

    def _angle_difference(self, angle1: float, angle2: float) -> float:
        """
        Calculate shortest angular difference between two angles

        Args:
            angle1, angle2: Angles in degrees

        Returns:
            Shortest angular difference (-180 to 180)
        """
        diff = (angle1 - angle2) % 360
        if diff > 180:
            diff -= 360
        return diff

    def _apply_smoothing(self, values: List[float]) -> float:
        """
        Apply smoothing to a list of values

        Args:
            values: List of values to smooth

        Returns:
            Smoothed value
        """
        if not values:
            return 0.0

        # Use exponential moving average
        weights = np.array([self.smoothing_factor ** i
                          for i in range(len(values) - 1, -1, -1)])
        weights /= weights.sum()

        return np.average(values, weights=weights)

    def get_basket_position(self, angle: float,
                           basket_width: float = 45.0) -> Optional[str]:
        """
        Determine which basket (left/right) the current angle is in

        Args:
            angle: Current rotation angle
            basket_width: Width of each basket in degrees

        Returns:
            'left', 'right', or None if not in a basket
        """
        # Left basket: 225-315 degrees (270 ± 45)
        # Right basket: 45-135 degrees (90 ± 45)

        normalized_angle = angle % 360

        if 225 <= normalized_angle <= 315:
            return 'left'
        elif 45 <= normalized_angle <= 135:
            return 'right'
        else:
            return None

    def reset(self):
        """Reset the processor state"""
        self.current_angle = 0.0
        self.previous_angle = 0.0
        self.angular_velocity = 0.0
        self.previous_timestamp = None
        self.angle_history.clear()
        self.velocity_history.clear()