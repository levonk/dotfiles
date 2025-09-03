#!/usr/bin/env python3

import os
import subprocess
import sys
import argparse
from typing import Optional

# ANSI escape codes for colored output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

def colored(text, color_code):
    """
    Return colored text using ANSI escape codes.
    """
    global use_color
    return f"{color_code}{text}{Colors.RESET}" if use_color else text

def check_command_exists(command):
    """
    Checks if a command exists in the system's PATH.
    """
    try:
        subprocess.run([command, "--version"], check=False, capture_output=True)
        return True
    except FileNotFoundError:
        return False

def run_command(command, dry_run=False):
    """
    Runs a shell command. If dry_run is True, it only prints the command.
    """
    print(colored(f"Running: {command}", Colors.BLUE))
    if not dry_run:
        try:
            subprocess.run(command, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(colored(f"Error running command: {e}", Colors.RED))
            sys.exit(1)

def detect_env_manager(directory="."):
    """
    Detects which environment manager is used in the given directory
    based on the presence of specific files.
    Returns a string representing the detected manager ('poetry', 'pdm', 'pipenv', 'conda', 'requirements', 'none').
    """
    if os.path.exists(os.path.join(directory, "pyproject.toml")):
        try:
            with open(os.path.join(directory, "pyproject.toml"), 'r') as f:
                content = f.read()
                if "poetry.dependencies" in content:
                    return "poetry"
                elif "tool.pdm" in content:
                    return "pdm"
                else:
                    return "none"
        except Exception as e:
            print(colored(f"Error reading pyproject.toml: {e}", Colors.RED))
            return "none"

    elif os.path.exists(os.path.join(directory, "Pipfile")):
        return "pipenv"
    elif os.path.exists(os.path.join(directory, "environment.yml")):
        return "conda"
    elif os.path.exists(os.path.join(directory, "requirements.txt")):
        return "requirements"
    else:
        return "none"

def detect_python_version(directory=".") -> Optional[str]:
    """
    Detects if the project is likely Python 2 or Python 3 based on various indicators.
    Returns "2" or "3" or "unknown".
    """
    if os.path.exists(os.path.join(directory, "__future__.py")):
        return "3"  # presence of __future__.py suggests it's trying to be compatible with py3

    if os.path.exists(os.path.join(directory, "setup.py")):
        try:
            with open(os.path.join(directory, "setup.py"), 'r') as f:
                content = f.read()
                if "python_requires='<3'" in content:
                    return "2"
        except Exception as e:
            print(colored(f"Error reading setup.py: {e}", Colors.RED))

    # Look for syntax differences
    if os.path.exists(os.path.join(directory, "main.py")):
        try:
            with open(os.path.join(directory, "main.py"), 'r') as f:
                content = f.read()
                if "print " in content and not "print(" in content:
                    return "2"
        except Exception as e:
            print(colored(f"Error reading main.py, skipping: {e}", Colors.RED))

    return "unknown"

def get_pyenv_python_version(directory=".") -> Optional[str]:
    """
    Gets the python version specified by pyenv local
    Returns None if pyenv local doesn't exist
    """
    has_pyenv = check_command_exists("pyenv")
    if has_pyenv == False:
        return None
    try:
        #If there is a local python version specified with `pyenv local`,
        #that command will output the version. Otherwise, it will return an
        #error. For simplicity, if any exception occurs, we skip checking
        #for a python version and leave python version management to the
        #env manager.
        pyenv_version_output = subprocess.check_output(["pyenv", "local"]).decode("utf-8").strip()
        print(colored(f"pyenv version detected: {pyenv_version_output}", Colors.GREEN))
        return pyenv_version_output
    except:
        print(colored("No pyenv python version detected.", Colors.YELLOW))
        return None


def main(args): # Removed dry_run, it is now part of args
    """
    Main function to detect the environment and run appropriate commands.
    """
    global use_color
    use_color = not args.no_color

    # Check for essential commands
    has_pyenv = check_command_exists("pyenv")
    has_uv = check_command_exists("uv")
    has_virtualenv = check_command_exists("virtualenv")
    has_poetry = check_command_exists("poetry")

    env_manager = detect_env_manager()
    print(colored(f"Detected environment manager: {env_manager}", Colors.GREEN))

    python_version = detect_python_version()
    print(colored(f"Detected Python version: {python_version}", Colors.GREEN))

    specified_python_version = args.python_version
    if specified_python_version:
        print(colored(f"CLI Specified Python Version: {specified_python_version}", Colors.GREEN))
    else:
        specified_python_version = get_pyenv_python_version()

    if has_pyenv:
        # Determine python version
        #If there is a local python version specified with `pyenv local`,
        #that command will output the version. Otherwise, it will return an
        #error. For simplicity, if any exception occurs, we skip checking
        #for a python version and leave python version management to the
        #env manager.
        print (colored("pyenv is detected.", Colors.GREEN))
        if specified_python_version:
            if args.create != True:
                print (colored("setting python version is only intended if used with a requirements.txt or setup.py project.  Did you intend to create?", Colors.YELLOW))
            run_command(f"pyenv local {specified_python_version}", args.dry_run)

    #Handle environment creation based on which environment manager is present
    if env_manager == "requirements" or (env_manager == "none" and args.create):

        if env_manager == "none":
            print (colored("Fresh Directory Detected. Creating Opinionated Setup: pyenv + venv + uv", Colors.GREEN))
        else:
            print (colored("requirements.txt Detected", Colors.GREEN))

        if has_pyenv:

            if has_uv and python_version != "2":
                print(colored("requirements.txt project found", Colors.GREEN))
                print(colored("pyenv/venv/uv detected", Colors.GREEN))
                print(colored("Create: python3 -m venv .venv", Colors.GREEN))
                if args.create:
                    run_command("python3 -m venv .venv", args.dry_run)
                run_command("source .venv/bin/activate", args.dry_run)
                update_cmd = "uv pip install -r requirements.txt"
                if args.update:
                    update_cmd += " --upgrade"
                run_command(update_cmd, args.dry_run)
                # create pyproject.toml
            else:

                print(colored("pyenv, but requires uv/venv found", Colors.RED))
                print (colored("please install pyenv with these.  Exiting.", Colors.RED))
                sys.exit(1)

        else:
            print(colored("pyenv NOT detected. Recommending pyenv.  Please install.", Colors.RED))
            sys.exit(1)
    elif env_manager in ("poetry", "pdm", "pipenv"):
        update_command = ""
        if env_manager == "poetry":
            update_command = "poetry update"
        elif env_manager == "pdm":
            update_command = "pdm update"
        elif env_manager == "pipenv":
            update_command = "pipenv update"

        print(colored(f"{env_manager} and pyenv detected", Colors.GREEN))
        print(colored(f"Using pyenv and {env_manager} to manage", Colors.GREEN))

        if has_pyenv == False:
            print (colored("Cannot manage the project due to a missing tool: pyenv.  Please install.", Colors.RED))
            sys.exit(1)

        if python_version == "2":
            print(colored(f"{env_manager} cannot be used to manage python 2", Colors.RED))
            sys.exit(1)

        command = f"{env_manager} env use $(pyenv which python)"
        env_exists_command = f"{env_manager} env info"
        if args.create == True:
            if env_manager == "poetry":
                print(colored("There is not a create command for poetry.  Please install", Colors.RED))
                print (colored("Instead, create a pyproject.toml with `poetry init`", Colors.YELLOW))
            run_command(command, args.dry_run)

        if args.update == True:
            run_command(update_command, args.dry_run)

    elif env_manager == "conda":
        print(colored("Using conda", Colors.GREEN))
        if args.create:
            run_command("conda env create -f environment.yml", args.dry_run)
        if args.update:
            run_command("conda env update -f environment.yml", args.dry_run)

    else:
        print(colored("No environment manager detected.", Colors.RED))
        if check_command_exists("pip"):
            print("A requirements.txt file was not found, however pip is present.  It is recommended that you install a proper dependency and environment manager such as poetry or pdm.")
        else:
            print("Please install a proper dependency and environment manager such as poetry or pdm.")
        sys.exit(1)

# The following are "opinionated" in addition to the other choices.
# A. Force creating a virtualenv, the environment if it's not there
# B. If a version is available in .python-version then we also use this
# C. If --version is passed in as a parameter on the cli, the we use that version regardless
# D. If the program is python2, then exit, this should not be supported.

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intelligently set up Python environments.")

    # Add command-line arguments
    parser.add_argument("--create", action="store_true", help="Create the environment if it doesn't exist")
    parser.add_argument("--update", action="store_true", help="Update dependencies")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing them")
    parser.add_argument("--python-version", type=str, help="Specify Python version")
    parser.add_argument("--no-color", action="store_true", help="Disable colored output")

    args = parser.parse_args()
    main(args)