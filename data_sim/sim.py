import math

K = 100000

DELTA_T = 10

def golden_search(function, min_range, max_range, tolerance):

    if max_range - min_range < tolerance:

        return (max_range + min_range) / 2

    golden_ratio = (1 + math.sqrt(5)) / 2

    x1 = max_range - (max_range - min_range) / golden_ratio
    x2 = min_range + (max_range - min_range) / golden_ratio

    fx1 = function(x1)
    fx2 = function(x2)

    if fx1 < fx2:

        return golden_search(function, min_range, x2, tolerance)
    
    return golden_search(function, x1, max_range, tolerance)

def pointInCircle(circle_x, circle_y, point_x, point_y, radius):
    return (circle_x - point_x) ** 2 + (circle_y - point_y) ** 2 < radius ** 2

def pointInWarpZone(x, y, z):

    if pointInCircle(K, 1.28 * K, x, y, .65 * K):
        return True

    if x < 1.4 * K:

        if y < .4 * K:
            return not pointInSquare(0, 0, x, z, 2.56 * K)

        if y < 1.28 * K:
            return not pointInSquare(0, 0, x, z, .8 * K)
    else:
        # Once I figure out if there are moon side warp zones, they will go here.
        return False

    return False

def pointInSquare(square_x, square_y, point_x, point_y, length):
    # Check if a point is in a square with a certain side length.

    length = length / 2

    in_x_range = ((point_x - square_x) < length) and ((point_x - square_x) > -length)
    in_y_range = ((point_y - square_y) < length) and ((point_y - square_y) > -length)

    return in_x_range and in_y_range

def accel(v, d):
    G = 10
    R = (100000 / 3) * (1 + math.sqrt(10))
    return min(1, d / 40000) + (v / 100) - (G * R * R) / ((R + d) ** 2)

def single_sim(start_x, start_y, start_y_vel, start_x_vel, assume_inf_moon = False, delta_t = DELTA_T):

    x_pos = start_x
    y_pos = start_y

    t = 0

    y_vel = start_y_vel
    ground_velocity = start_x_vel

    path = [(x_pos, y_pos)]

    satisfied = False
    moon_collision = False

    while not satisfied:
        # RK4 Integration
        k1v = accel(ground_velocity, y_pos)
        k1x = y_vel

        k2v = accel(ground_velocity, y_pos + (delta_t / 2) * k1x)
        k2x = y_vel + (delta_t / 2) * k1v

        k3v = accel(ground_velocity, y_pos + (delta_t / 2) * k2x)
        k3x = y_vel + (delta_t / 2) * k2v

        k4v = accel(ground_velocity, y_pos + delta_t * k3x)
        k4x = y_vel + delta_t * k3v

        # Calculate new y position, and new y velocity based on integration
        n_y_pos = y_pos + delta_t / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
        y_vel = y_vel + delta_t / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)

        # Calculate new X position based on constant velocity dead reckoning
        n_x_pos = x_pos + ground_velocity * delta_t

        t = t + delta_t

        # Check for moon collision
        if pointInSquare(200000, 0, n_x_pos, 0, 31000) and n_y_pos < .8 * K:
            lerp_value = (.8 * K - y_pos) / (n_y_pos - y_pos)
            n_x_pos = (n_x_pos - x_pos) * lerp_value + x_pos
            
            satisfied = True
            moon_collision = True

        if assume_inf_moon:

            # Assume the moon is infinitely large, for easier implementation later. 

            if y_vel < 0 and n_y_pos < .8 * K:
                lerp_value = (.8 * K - y_pos) / (n_y_pos - y_pos)
                n_x_pos = (n_x_pos - x_pos) * lerp_value + x_pos
                n_y_pos = .8 * K
                
                satisfied = True
                moon_collision = True

                # We are going downward, and we just crossed the moons axis. 

        if n_y_pos < 0:
            # Earth collision

            # Create estimate of actual impact point based on projected position, by assuming a linear trajectory between pos, and new position

            lerp_value = y_pos / (y_pos - n_y_pos)
            n_x_pos = (n_x_pos - x_pos) * lerp_value + x_pos

            n_y_pos = 0 # Cap y position, cause alt can never be negative. This allows us to detect a ground impact point later

        x_pos = n_x_pos
        y_pos = n_y_pos

        path.append((x_pos, y_pos))

        # If altitude is less than zero, or greater than 30 minutes in path time. Or if altitude is greater than 350k (altitude probably runaway)
        # There is a special case here, that if you are above 350k, the projected path can go above its 350k cap, up to 100k + your current alt
        # this is to ensure that you always have a decent idea of your trajectory. 

        if y_pos <= 0 or y_pos > 3 * K:
            satisfied = True

    return path, moon_collision

def determine_path_time(path):

    return len(path) * DELTA_T

def calculate_moon_trajectory(start_y, start_y_vel):

    # Check if this setup is inherently unstable.

    stationary_path, _ = single_sim(0, start_y, start_y_vel, 0)

    # Check if last coordinate is out of bounds
    if stationary_path[-1][1] > 3 * K:
        # Coordinate out of bounds, y velocity too fast.
        return None

    # Next, calculate the maximum ground velocity (velocity where the path exceeds bounding)
    min_groundspeed = 0 # we know this is stable, because we just checked. 
    max_groundspeed = 1000 # Large enough that we can practically guarantee that it is unstable. 
    # Perform binary search

    while max_groundspeed - min_groundspeed > .01: # Very small tolerance, for maximum accuracy

        midpoint_velocity = (min_groundspeed + max_groundspeed) / 2

        moving_path, _ = single_sim(0, start_y, start_y_vel, midpoint_velocity)

        if moving_path[-1][1] > 3 * K:
            # Point unstable. Adjust bounds accordingly. 
            max_groundspeed = midpoint_velocity
        else:
            # Point stable. Adjust bounds accordingly.
            min_groundspeed = midpoint_velocity


    fastest_speed = min_groundspeed
    moving_path, _ = single_sim(0, start_y, start_y_vel, fastest_speed)

    # midpoint_velocity = (min_groundspeed + max_groundspeed) / 2
    # moving_path, _ = single_sim(0, start_y, start_y_vel, midpoint_velocity)
    # return moving_path, 0, 0

    # Check that at best, we can still reach the moon
    if moving_path[-1][0] < 2 * K:
        return None # Too short!
    
    # Now we need to find the optimal ground velocity to hit the moon. 
    # We can now use another step of binary search. Since we know that the range 0 -> fastest_speed encompasses an entirely stable range, and that the moon is somewhere in that range. 

    min_groundspeed = 0
    max_groundspeed = fastest_speed

    while max_groundspeed - min_groundspeed > .0001: # Very small tolerance, for maximum accuracy

        midpoint_velocity = (min_groundspeed + max_groundspeed) / 2

        moving_path, _ = single_sim(0, start_y, start_y_vel, midpoint_velocity, assume_inf_moon = True)

        # print(moving_path[-1][0], min_groundspeed, max_groundspeed)

        if moving_path[-1][0] > 2 * K:
            # Point too far. Adjust bounds accordingly. 
            max_groundspeed = midpoint_velocity
        else:
            # Point too short. Adjust bounds accordingly.
            min_groundspeed = midpoint_velocity

    # Now check if the path intersected any warp zones along the way. 
    for x, y in moving_path:
        if pointInWarpZone(x, y, 0):
            return None

    return moving_path, determine_path_time(moving_path), (max_groundspeed + min_groundspeed) / 2

def find_ascent_profile(target_y, target_y_vel):

    positions, _ = single_sim(0, target_y, -target_y_vel, 0)

    if positions[-1][1] > 300000:
        return None

    return positions[::-1]

if __name__ == '__main__':
    # {'start_y': np.float64(), 'start_y_vel': np.float64(), 'best_velocity': 104.19459142940468}

    best_launch, _, _ = calculate_moon_trajectory(118844.22110552764, 278.8944723618091)

    from matplotlib import pyplot as plt

    fig, ax = plt.subplots()

    ax.set_aspect('equal', adjustable='box')

    xs = [point[0] for point in best_launch]
    ys = [point[1] for point in best_launch]

    # Decorations
    circle1 = plt.Circle((100000, 128000), 60000, color='red', fill=True, linewidth=0)
    rect = plt.Rectangle((40000, 50000), 120000, 78000, color='red', fill=True, linewidth=0)
    circle2 = plt.Circle((200000, 80000), 15500, color='green', fill=False, linewidth=2)
    for shape in (circle1, rect, circle2):
        ax.add_patch(shape)

    ax.plot(xs, ys)
    ax.plot([200000], [80000], 'o')

    plt.show()