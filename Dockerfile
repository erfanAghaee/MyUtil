# Use Ubuntu 20.04 as the parent image
FROM ubuntu:20.04

# Update the package lists and install necessary dependencies
RUN apt-get update && \
    apt-get install -y vim python3 g++ cmake && \
    apt-get clean

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Create a build directory
RUN mkdir build

# Create a tmp directory for input/output
RUN mkdir tmp

# Compile the C++ code with CMake
RUN cd build && cmake ../cpp_code && make

# Make the Python script executable
RUN chmod +x python_code/main.py

# Define the command to run your application
CMD ["python3", "python_code/main.py"]
