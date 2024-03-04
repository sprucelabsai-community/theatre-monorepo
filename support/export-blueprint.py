import os
import re
import yaml
import argparse
from collections import OrderedDict
from dotenv import dotenv_values

# Set up argument parsing
parser = argparse.ArgumentParser(description='Update and merge blueprint configurations.')
parser.add_argument('write-to', type=str, help='Path to write to', default='blueprint.yml')
parser.add_argument('--unit-config', type=str, help='Path to a unit-specific blueprint.yml file.', default='')
args = parser.parse_args()

def extract_skill_envs(packages_dir):
    """Extract environment variables from top-level .env files, keyed by skill."""
    skill_envs = OrderedDict()
    skill_name_pattern = re.compile(r'.*-(.*)-skill')
    lumena_skills = OrderedDict()
    spruce_skills = OrderedDict()
    predefined_order = ['universal', 'mercury', 'heartwood']

    # Loop through all top-level directories in packages_dir

    for skill_dir in sorted(next(os.walk(packages_dir))[1]):
        skill_path = os.path.join(packages_dir
        , skill_dir)
        env_file_path = os.path.join(skill_path, '.env')
        if os.path.exists(env_file_path):
            # Extract the skill name from the directory name
            match = skill_name_pattern.match(skill_dir)
            if match:
                skill_name = match.group(1)
                env_values = dotenv_values(env_file_path)
                if skill_dir.startswith('lumena'):
                    lumena_skills[skill_name] = env_values
                elif skill_dir.startswith('spruce'):
                    spruce_skills[skill_name] = env_values

    # Sort Lumena skills alphabetically
    lumena_skills = OrderedDict(sorted(lumena_skills.items()))

    # Sort Spruce skills alphabetically
    spruce_skills = OrderedDict(sorted(spruce_skills.items()))

    # Combine Lumena and Spruce skills
    skill_envs.update(lumena_skills)
    skill_envs.update(spruce_skills)

    # Ensure the order of predefined keys within each skill group
    for skill in predefined_order:
        if skill in skill_envs:
            skill_envs.move_to_end(skill, last=False)

    return skill_envs

def ingest_blueprint(blueprint_path, new_blueprint_path, skill_envs, unit_specific_blueprint_path=''):
    """Replicate certain sections of the original blueprint, update env section, and apply unit-specific configurations."""
    with open(blueprint_path, 'r') as file:
        blueprint = yaml.safe_load(file)

    # Initialize updated blueprint with original values
    updated_blueprint = {
        'skills': sorted(blueprint.get('skills', [])),
        'admin': blueprint.get('admin', []),
        'env': blueprint.get('env', {})
    }

    # Extract and update universal environment variables from the original blueprint
    universal_env = {k: v for item in updated_blueprint['env'].get('universal', []) for k, v in item.items()}
    updated_universal = [{k: v} for k, v in universal_env.items()]

    # Update universal in updated_blueprint to maintain consistency
    updated_blueprint['env']['universal'] = updated_universal

    # Merge environment variables from .env files into each skill
    for skill_name, env_vars in skill_envs.items():
        # Start with existing skill-specific environment variables, if any
        updated_skill_env = updated_blueprint['env'].get(skill_name, [])
        skill_env_dict = {k: v for d in updated_skill_env for k, v in d.items()}
        
        # Update with new values from .env, excluding universal keys if they are not explicitly defined
        for k, v in env_vars.items():
            if k not in universal_env or (k in universal_env and v != universal_env[k]):
                skill_env_dict[k] = v
                
        # Convert back to list of dicts format for serialization
        updated_blueprint['env'][skill_name] = [{k: v} for k, v in sorted(skill_env_dict.items())]

    # Merge unit-specific blueprint if provided
    if unit_specific_blueprint_path:
        with open(unit_specific_blueprint_path, 'r') as file:
            unit_specific_blueprint = yaml.safe_load(file)
        for key, new_values in unit_specific_blueprint.get('env', {}).items():
            existing_values = updated_blueprint['env'].get(key, [])
            existing_dict = {k: v for d in existing_values for k, v in d.items()}
            
            # Check if new_values is a list of dictionaries and convert it to a dictionary
            new_values_dict = {list(item.keys())[0]: list(item.values())[0] for item in new_values} if isinstance(new_values, list) else new_values

            # Merge new values, prioritizing unit-specific values over existing ones
            for k, v in new_values_dict.items():
                if k not in universal_env or (k in universal_env and v != universal_env[k]):
                    existing_dict[k] = v

            # Update the skill's env in the updated_blueprint, sorted
            updated_blueprint['env'][key] = [{k: v} for k, v in sorted(existing_dict.items())]

    # Serialize the updated blueprint to a YAML string
    yaml_str = yaml.safe_dump(updated_blueprint, default_flow_style=False, sort_keys=False, width=72, indent=2)

    # Add newlines before 'admin' and 'env' sections
    yaml_str = yaml_str.replace('\nadmin:', '\n\nadmin:').replace('\nenv:', '\n\nenv:')

    # Write the modified YAML string to a new file
    with open(new_blueprint_path, 'w') as file:
        file.write(yaml_str)


# Main execution
if __name__ == "__main__":
    # Define the path for the original and new blueprint
    packages_dir = './packages'
    blueprint_path = 'blueprint.yml'
    new_blueprint_path = getattr(args, 'write-to')
    unit_config_path = args.unit_config

    # Extract skill environments and update blueprint
    skill_envs = extract_skill_envs(packages_dir)
    ingest_blueprint(blueprint_path, new_blueprint_path, skill_envs, unit_config_path)
