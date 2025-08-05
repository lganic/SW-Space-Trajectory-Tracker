# Create an approximation of a ballistics based trajectory from a target point and velocity. 

from sim import single_sim

# def find(total_time_from_ground)

from matplotlib import pyplot as plt
import numpy as np


{'start_y': 114321.60804020101, 'start_y_vel': 284.9246231155779, 'best_velocity': 77.71101900289068}
{'start_y': 118844.22110552764, 'start_y_vel': 278.8944723618091, 'best_velocity': 72.82229045813438}

dt = .01
positions, _ = single_sim(0, 118844.22110552764, -278.8944723618091, 0, delta_t = dt)

positions = positions[::-1]

xs = [point[0] for point in positions]
ys = [point[1] for point in positions]

y_speeds = []

for y_i in range(len(ys) - 1):
    y_speeds.append((ys[y_i + 1] - ys[y_i]) / dt)

y_speeds.append((ys[y_i + 1] - ys[y_i]) / dt)

# Filter out adjusted coordinate
y_speeds = y_speeds[1:]
ys = ys[1:]

# Your data
ys = np.array(ys)
y_speeds = np.array(y_speeds)

# Linear regression: fit a line y = m*x + b
m, b = np.polyfit(ys[int(.2*len(ys)):], y_speeds[int(.2*len(ys)):], 1)

# Generate regression line values
regression_line = m * ys + b

print(m, b)
# Plot original data
plt.plot(ys, y_speeds, label='Actual', marker='o')

# Plot regression line
plt.plot(ys, regression_line, label='Linear Regression', linestyle='--')

# Add labels/legend
plt.xlabel('ys')
plt.ylabel('y_speeds')
plt.legend()
plt.show()