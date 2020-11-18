#!/usr/bin/python3
"""
Read configuration file and desired playbook file and generates
ansible-playbook command line.
"""

from argparse import ArgumentParser
from os.path import isfile
import subprocess as sp
from sys import exit, argv
from yaml import load as load_yaml, YAMLError

environments_available = ["dev", "stage", "prod"]

def main():
    """
    Main method.
    """
    environment, config_file, playbook = parse_arguments()

    # verify files
    files_exist(config_file, playbook)

    # verify env
    if environment not in environments_available:
        print("Environment is fake news")
        exit(1)

    # open config file.
    mongo_config_details = read_mongo_yaml_config(config_file)

    # call ansible run with the mongo db commands.
    ansible_run(playbook,
                mongo_config_details.get("database"),
                mongo_config_details.get("username"),
                mongo_config_details.get("password"),
                mongo_config_details.get("dbroles"))

    # ansible_run(ansible_call)

    print("User {} created in database {} with role {} and password {}"
          .format(mongo_config_details.get("username"),
                  mongo_config_details.get("database"),
                  mongo_config_details.get("dbroles"),
                  mongo_config_details.get("password")))

def ansible_run(playbook_file, db_name, db_user, db_pwd, db_roles):
    # in case you want to mute ansible, set stdout to PIPE
    #process = sp.Popen(ansible_command, stdout=sp.PIPE, shell=True)

    # ansible cli string creation, this can be replaced with ansible.runner call in the future.
    ansible_command = ansible_playbook_cli_string(playbook_file, db_name,
                                                  db_user, db_pwd, db_roles)

    process = sp.Popen(ansible_command, shell=True)
    output, error = process.communicate()

    rc = process.returncode
    if rc > 0:
        print("Everything was going fine, but things happened")
        exit(1)

def ansible_playbook_cli_string(playbook_file, db_name, db_user, db_pwd, db_roles):
    """
    This function is only to create the cli string, can be removed when migrated
    to ansible runner python api.
    """
    ansible_call = "ansible-playbook {} -i hosts --extra-vars \"database={} " \
                   "username={} password={} dbroles={}\"" \
                   .format(playbook_file, db_name, db_user, db_pwd, db_roles)
    return ansible_call

def read_mongo_yaml_config(config_file_name):
    with open(config_file_name, 'r') as stream:
        try:
            yaml_dict = load_yaml(stream)
        except YAMLError as exc:
            print(exc)
    return yaml_dict

def parse_arguments():
    """
    Use argparse to handle cli arguments
    """
    # Define arguments.
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(help="Environment is one of {}".format(environments_available), dest='environment',
            metavar='ENVIRONMENT')
    parser.add_argument(help="YAML Config file", dest='config_file',
            metavar='CONFIG-FILE')
    parser.add_argument(help="Playbook file", dest='playbook',
            metavar='PLAYBOOK')
    # Parse arguments.
    args = parser.parse_args()
    return args.environment, args.config_file, args.playbook


def files_exist(*files):
    """
    Verify if Files exists in the system
    """
    [ exit("Check files") for item in files if not isfile(item) ]


if __name__ == "__main__":
    exit(main())
