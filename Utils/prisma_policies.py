# First, if you haven't installed pyyaml, run the following command:
# pip3 install pyyaml
# To run this script, use the following command:
# python3 prisma_policies.py "Policy Name"

import sys
import os
import re
import yaml  # Install via 'pip3 install pyyaml'


def clean_input(s):
    """Strip leading and trailing whitespace and quotes from a string."""
    return s.strip().strip('"').strip("'")


def format_rql(rql):
    """Insert newline before 'AND', 'and', 'OR', 'or'."""
    # Ensure consistent spacing around operators
    rql = re.sub(r'\s+(AND|and|OR|or)\s+', r' \1 ', rql)
    # Insert newline before operators
    rql = re.sub(r'\s+(AND|and|OR|or)\s+', r'\n\1 ', rql)
    return rql


# Custom string classes
class QuotedString(str):
    pass


class UnquotedString(str):
    pass


def create_yaml_file(json_data: dict):
    """Create a YAML file with the given name, then prompt engineer for policy details."""
    # Replace spaces with underscores for the filename
    filename = json_data['name'].replace(' ', '_')
    # Optionally, convert to lowercase
    # filename = filename.lower()
    # Add .yml extension
    filename_with_extension = f"{filename}.yml"

    # Start building the data dictionary for YAML
    data = {}

    # Set the 'name' and 'short_name' fields to filename (with underscores)
    data['name'] = filename

    # Prompt for 'description' and clean input
    data['description'] = QuotedString(json_data['description'])
    data['short_name'] = filename

    # Prompt for 'type' (default is 'config') and clean input
    data['type'] = 'config'

    # -------------------------------UNCOMMENT BELOW TO SELECT CLOUD TYPE--------------------------------
    # Prompt for 'cloud_type' (choices: azure, AWS, GCP) and clean input
    # while True:
    #     cloud_type = clean_input(
    #         input("Enter the cloud type (azure, AWS, or GCP): "))
    #     if cloud_type.lower() in ['azure', 'aws', 'gcp']:
    #         data['cloud_type'] = cloud_type.lower()
    #         break
    #     else:
    #         print("Invalid cloud type. Please enter 'azure', 'AWS', or 'GCP'.")
    data['cloud_type'] = json_data['cloudType']
    # -------------------------------UNCOMMENT ABOVE TO SELECT CLOUD TYPE--------------------------------

    # -------------------------------UNCOMMENT BELOW TO SELECT SEVERITY --------------------------------
    # Prompt for 'severity' and clean input
    # while True:
    #     severity = clean_input(
    #         input("Enter the severity (high, medium, low, informational): "))
    #     if severity.lower() in ['high', 'medium', 'low', 'informational']:
    #         data['severity'] = severity.lower()
    #         break
    #     else:
    #         print("Invalid severity. Please enter 'high', 'medium', 'low', or 'informational'.")
    data['severity'] = 'high'
    # -------------------------------UNCOMMENT ABOVE TO SELECT SEVERITY --------------------------------

    data['recommendation'] = QuotedString(json_data['recommendation'])

    # TODO: conditionally handle the labels syntax/formatting
    labels_input = json_data['labels']
    labels_list = [clean_input(label)
                   for label in labels_input.split(',') if label.strip()]
    if not labels_list:
        print("No labels provided. Exiting.")
        return
    # Insert severity label
    # Insert severity label
    labels_list.insert(0, UnquotedString("eis"))
    data['labels'] = labels_list

    # Build 'compliance_standards' section
    data['compliance_standards'] = []
    compliance = {}
    # Prompt for 'name' (default 'EIS_Beta' or optional 'EIS')

    compliance['name'] = 'EIS_Beta'
    # Prompt for 'requirement' and clean input

    compliance['requirement'] = UnquotedString(json_data['requirement'])
    # Prompt for 'section' and clean input
    section_input = clean_input(
        input("Enter the compliance section: "))
    compliance['section'] = QuotedString(section_input)
    data['compliance_standards'].append(compliance)

    # Build 'policy_subtypes' section
    data['policy_subtypes'] = {
        'runtime': {
            'saved_search': False,
            'rql': None  # Placeholder for 'rql'
        }
    }
    # Prompt for 'rql' (assuming it's a multi-line string)
    print("Enter the RQL (end with an empty line):")
    rql_lines = []
    try:
        while True:
            line = input()
            if line == '':
                break
            rql_lines.append(line)
    except EOFError:
        # Handle unexpected EOF
        pass
    rql = '\n'.join(rql_lines)
    # Format the rql string
    rql = format_rql(rql)
    data['policy_subtypes']['runtime']['rql'] = rql

    # Custom Dumper class to adjust indentation
    class IndentDumper(yaml.SafeDumper):
        def increase_indent(self, flow=False, indentless=False):
            return super(IndentDumper, self).increase_indent(flow, False)

    # Custom representer functions
    def represent_str(dumper, data):
        if isinstance(data, QuotedString):
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')
        elif isinstance(data, UnquotedString):
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='')
        elif '\n' in data:
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
        elif any(c in data for c in [' ', '"', "'", "$", "#", "@", ":", "."]):
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')
        else:
            return dumper.represent_scalar('tag:yaml.org,2002:str', data)

    def represent_list(dumper, data):
        return dumper.represent_sequence('tag:yaml.org,2002:seq', data, flow_style=False)

    # Register custom representers
    IndentDumper.add_representer(str, represent_str)
    IndentDumper.add_representer(list, represent_list)
    IndentDumper.add_representer(QuotedString, represent_str)
    IndentDumper.add_representer(UnquotedString, represent_str)

    # Write the data to a YAML file
    try:
        with open(filename_with_extension, 'w') as file:
            yaml.dump(
                data,
                file,
                Dumper=IndentDumper,
                sort_keys=False,
                default_flow_style=False,
                indent=2
            )
        print(f"Created file: {filename_with_extension}")
    except Exception as e:
        print(f"An error occurred while writing the YAML file: {e}")


def create_yaml_files_from_dicts(dict_list):
    """Process a list of dictionaries and create a YAML file for each."""
    for json_data in dict_list:
        create_yaml_file(json_data)


if __name__ == "__main__":
    try:
        create_yaml_files_from_dicts(dict_list)
    except KeyboardInterrupt:
        print("\nScript interrupted by user. Exiting.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
