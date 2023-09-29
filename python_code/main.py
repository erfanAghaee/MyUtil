import subprocess
import os

def run_cpp_program():
    try:
        result = subprocess.run(["./build/main"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            print("C++ program output:")
            print(result.stdout)
        else:
            print("C++ program encountered an error:")
            print(result.stderr)
    except Exception as e:
        print("Error running C++ program:", str(e))

if __name__ == "__main__":
    print("Python program started.")
    # print(os.listdir("./tmp/"))
    # file_path ="./tmp/hello.txt"
    # with open(file_path, "r") as file:
    #     # Read the entire contents of the file into a string
    #     file_contents = file.read()
    #     print("File contents:")
    #     print(file_contents)


    run_cpp_program()

    with open("./tmp/hello.txt", "w") as file:
        # Write "hello" to the file
        file.write("hello")
    print("Python program finished.")