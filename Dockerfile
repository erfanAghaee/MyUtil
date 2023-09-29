# Use Ubuntu 20.04 as the parent image
FROM ubuntu:20.04

# Define an argument for the time zone
ARG TIMEZONE=UTC

# Set the timezone
ENV TZ=$TIMEZONE

# Define Python and Boost versions
ARG PYTHON_VERSION=3.8
ARG BOOST_VERSION=1.72

# Update the package lists and install necessary dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y vim python${PYTHON_VERSION} python${PYTHON_VERSION}-distutils python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev g++ cmake libboost-all-dev && \
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

# Create a virtual Python environment and activate it
RUN python3 -m venv venv

# Install Python dependencies from requirements.txt
RUN /bin/bash -c "source venv/bin/activate && pip install -r python_code/requirements.txt"


# Make the Python script executable
RUN chmod +x python_code/main.py

# Define the command to run your application within the virtual environment
CMD ["bash", "-c", "source venv/bin/activate && python${PYTHON_VERSION} python_code/main.py"]


# Prompt the user to select a time zone during the build process
# Example usage: docker build --build-arg TIMEZONE=America/New_York -t my_boost_docker .
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone