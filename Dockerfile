# Use Ubuntu 20.04 as the parent image
FROM ubuntu:20.04

# Define an argument for the time zone
ARG TIMEZONE=UTC

# Set the timezone
ENV TZ=$TIMEZONE

# Update the package lists and install necessary dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y vim python3 g++ cmake libboost-all-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*



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

# Prompt the user to select a time zone during the build process
# Example usage: docker build --build-arg TIMEZONE=America/New_York -t my_boost_docker .
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone