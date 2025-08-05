import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from tqdm import tqdm
from sklearn.linear_model import LinearRegression

from sim import calculate_moon_trajectory, find_ascent_profile, determine_path_time

size_vel = 200
size_pos = 200

# Grid setup
y_vals = np.linspace(100_000, 250_000, size_pos)
yv_vals = np.linspace(-300, 300, size_vel)
Y, YV = np.meshgrid(y_vals, yv_vals)

# Output grids
Z_time = np.full_like(Y, np.nan, dtype=float)
Z_vel = np.full_like(Y, np.nan, dtype=float)

tq = tqdm(total = size_vel * size_pos)

best_travel_time = 99**99
best_solution = None

# Evaluate the function on the grid
for i in range(Y.shape[0]):
    for j in range(Y.shape[1]):
        result = calculate_moon_trajectory(Y[i, j], YV[i, j])

        tq.update()

        if result is not None:
            _, travel_time, optimal_velocity = result

            ascent = find_ascent_profile(Y[i, j], YV[i, j])

            if ascent is None:
                continue

            travel_time += determine_path_time(ascent)

            Z_time[i, j] = travel_time
            Z_vel[i, j] = optimal_velocity

            if travel_time < best_travel_time:
                best_travel_time = travel_time
                best_solution = {'start_y': Y[i, j], 'start_y_vel': YV[i, j], 'best_velocity': optimal_velocity}


print(best_travel_time)
print(best_solution)

# Flatten inputs and mask valid data
mask = ~np.isnan(Z_time)
X = np.column_stack((Y[mask], YV[mask]))  # Inputs: start_y, start_y_vel

# Regression for travel time
y_time = Z_time[mask]
reg_time = LinearRegression().fit(X, y_time)
print("Travel time ≈ {:.4e} * start_y + {:.4e} * start_y_vel + {:.4e}".format(
    reg_time.coef_[0], reg_time.coef_[1], reg_time.intercept_))

# Regression for optimal velocity
y_vel = Z_vel[mask]
reg_vel = LinearRegression().fit(X, y_vel)
print("Optimal velocity ≈ {:.4e} * start_y + {:.4e} * start_y_vel + {:.4e}".format(
    reg_vel.coef_[0], reg_vel.coef_[1], reg_vel.intercept_))

# Surface plot for travel time
fig1 = plt.figure()
ax1 = fig1.add_subplot(111, projection='3d')
surf1 = ax1.plot_surface(Y, YV, Z_time, cmap='viridis', edgecolor='none')
ax1.set_xlabel('Start Y Position')
ax1.set_ylabel('Start Y Velocity')
ax1.set_zlabel('Travel Time')
ax1.set_title('Travel Time Surface')
fig1.colorbar(surf1, ax=ax1, shrink=0.5)

# Surface plot for optimal velocity
fig2 = plt.figure()
ax2 = fig2.add_subplot(111, projection='3d')
surf2 = ax2.plot_surface(Y, YV, Z_vel, cmap='plasma', edgecolor='none')
ax2.set_xlabel('Start Y Position')
ax2.set_ylabel('Start Y Velocity')
ax2.set_zlabel('Optimal Velocity')
ax2.set_title('Optimal Velocity Surface')
fig2.colorbar(surf2, ax=ax2, shrink=0.5)

plt.show()