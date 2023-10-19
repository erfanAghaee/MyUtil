import numpy as np
import matplotlib.pyplot as plt

# Define the logistic function
def logistic_function(k,x):
    print("(1 + np.exp(-k*x)): ",(1 + np.exp(-k*x)))
    return 1 / (1 + np.exp(-k*x))

def logist_function_test():
    k = 0.8
    start = -6
    end = 6
    # (start,end,k)
    coefs = [(-6,6,0.5),(-6,6,1),(-6,6,3),(-6,6,8),(-6,6,18),
             (-600,600,0.5),(-600,600,1),(-600,600,3),(-600,600,8),(-600,600,18),
             (0,600,0.5),(0,600,1),(0,600,3),(0,600,8),(-0,600,18)]
    # coefs = [(-600,600,3)]
    # Generate a range of values for the input variable 'x'

    for coef in coefs:
        k = coef[2]
        start = coef[0]
        end = coef[1]
        x = np.linspace(start, end, 100)  # Adjust the range and number of points as needed

        # Calculate the corresponding values of the logistic function
        y = logistic_function(k,x)

        # Plot the logistic function
        plt.plot(x, y)
        plt.xlabel('x')
        plt.ylabel('f(x)')
        plt.title('Logistic Function')
        plt.grid(True)
        plt.show()
        plt.savefig(f"./tmp/logistic_function_{start}-{end}_{k}.png")
        plt.clf()