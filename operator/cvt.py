#!/usr/bin/env python3
# Usage:
# ./convert-crd-to-yaml.py [input-crd.yaml] [output-clean-crd.yaml]
import yaml
import sys
import argparse
import os
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def extract_yaml_structure(data, path=""):
    """
    Recursively extract only the YAML field structure, removing unnecessary metadata.
    Improved to handle various CRD structures.
    """
    if data is None:
        return {}
        
    if isinstance(data, dict):
        # If schema has 'properties' field
        if "properties" in data:
            result = {k: extract_yaml_structure(v, f"{path}.{k}") for k, v in data["properties"].items()}
            
            # Handle additionalProperties (Kubernetes map/dictionary types)
            if "additionalProperties" in data:
                additional = data.get("additionalProperties", {})
                if isinstance(additional, dict):
                    if "properties" in additional:
                        # Complex additionalProperties definition
                        sample_key = "example-key"
                        result[sample_key] = extract_yaml_structure(additional, f"{path}.{sample_key}")
                    else:
                        # Simple type additionalProperties
                        result["example-key"] = extract_yaml_structure({}, f"{path}.example-key")
                    
            return result
        # Handle special schema types with 'x-kubernetes-*' fields
        elif any(k.startswith("x-kubernetes-") for k in data.keys()):
            # Return empty dict for these special fields
            return {}
        else:
            # Remove unnecessary metadata and keep only field names
            exclude_keys = {"description", "type", "items", "required", "format", "example", 
                          "enum", "minimum", "maximum", "pattern", "nullable", "default"}
            return {k: extract_yaml_structure(v, f"{path}.{k}") 
                   for k, v in data.items() 
                   if k not in exclude_keys}
    elif isinstance(data, list):
        if data:
            # For lists, use the first item as a representative sample
            sample = extract_yaml_structure(data[0], f"{path}[0]")
            return [sample] if sample else []
        return []
    else:
        # Return appropriate default values for basic types
        if isinstance(data, str):
            return ""
        elif isinstance(data, int):
            return 0
        elif isinstance(data, bool):
            return False
        else:
            return None

def find_schema(crd):
    """
    Function to find schema definition in CRD.
    Supports multiple locations to handle different CRD formats.
    """
    version_schemas = {}
    spec = crd.get("spec", {})
    
    # Method 1: Find schema in spec.versions[].schema
    versions = spec.get("versions", [])
    if versions:
        logger.info(f"Found {len(versions)} versions in CRD")
        for version in versions:
            version_name = version.get("name", "unknown")
            # Try various schema paths
            schema_paths = [
                ["schema", "openAPIV3Schema", "properties", "spec"],
                ["schema", "openAPIV3Schema"],
                ["validation", "openAPIV3Schema", "properties", "spec"],
                ["validation", "openAPIV3Schema"]
            ]
            
            schema = None
            used_path = None
            for path in schema_paths:
                current = version
                valid_path = True
                for key in path:
                    if isinstance(current, dict) and key in current:
                        current = current[key]
                    else:
                        valid_path = False
                        break
                
                if valid_path and current:
                    schema = current
                    used_path = path
                    logger.info(f"Found schema for version {version_name} at path {path}")
                    break
            
            if schema:
                # If 'spec' field is missing, create default structure
                if used_path and used_path[-1] != "spec":
                    # Try to find properties.spec
                    if isinstance(schema, dict) and "properties" in schema and "spec" in schema["properties"]:
                        schema = schema["properties"]["spec"]
                    # Otherwise use top level
                
                version_schemas[version_name] = schema
            else:
                logger.warning(f"Could not find schema for version {version_name}")
    
    # Method 2: Find schema in spec.validation (older CRD format)
    if not version_schemas and "validation" in spec:
        logger.info("Trying legacy validation path")
        validation = spec.get("validation", {})
        schema = validation.get("openAPIV3Schema", {})
        
        if schema:
            # Use CRD version as version name
            version_name = spec.get("version", "v1")
            logger.info(f"Found schema for version {version_name} at legacy location")
            
            # Check if we need to extract spec property
            if "properties" in schema and "spec" in schema["properties"]:
                schema = schema["properties"]["spec"]
                
            version_schemas[version_name] = schema
    
    # Method 3: Find schema directly in single version format
    if not version_schemas and "openAPIV3Schema" in spec:
        logger.info("Found schema in single version format")
        schema = spec.get("openAPIV3Schema", {})
        version_name = spec.get("version", "v1")
        
        if "properties" in schema and "spec" in schema["properties"]:
            schema = schema["properties"]["spec"]
            
        version_schemas[version_name] = schema
    
    return version_schemas

def get_crd_info(crd, input_file):
    """
    Extract essential CRD information and provide fallback values for missing fields.
    """
    spec = crd.get("spec", {})
    
    # Extract group
    group = spec.get("group", "")
    if not group:
        # Try to find in other locations
        names = spec.get("names", {})
        if "group" in names:
            group = names.get("group")
        else:
            logger.warning("Could not find group in CRD, using 'custom.resource' as fallback")
            group = "custom.resource"
    
    # Extract kind
    kind = spec.get("names", {}).get("kind", "")
    if not kind:
        # Try to extract from metadata name
        metadata_name = crd.get("metadata", {}).get("name", "")
        if metadata_name:
            # Custom resources typically follow plural.group.com format
            logger.warning(f"Could not find kind in CRD, attempting to extract from {metadata_name}")
            parts = metadata_name.split(".")
            if parts:
                # Convert to CamelCase to create kind
                kind = "".join(part.capitalize() for part in parts[0].split("-"))
        
        if not kind:
            logger.warning("Could not determine kind, using 'CustomResource' as fallback")
            kind = "CustomResource"
    
    # Extract metadata.name
    metadata_name = crd.get("metadata", {}).get("name", "")
    if not metadata_name:
        logger.warning("Could not find metadata.name, using input file name as fallback")
        metadata_name = os.path.splitext(os.path.basename(input_file))[0]
    
    # Create name for custom resource instance (convert from plural in metadata.name)
    instance_name = metadata_name.split(".")[0] if "." in metadata_name else metadata_name
    # If contains hyphen, use only first part
    instance_name = instance_name.split("-")[0] if "-" in instance_name else instance_name
    # Try to remove plural suffix
    if instance_name.endswith("s") and len(instance_name) > 3:
        instance_name = instance_name[:-1]
    # Create short instance name
    instance_name = f"{instance_name}-example"
    
    return group, kind, metadata_name, instance_name

def convert_crd_to_yaml(input_file, output_file, verbose=False):
    """
    Convert Kubernetes CRD to a clean YAML structure.
    """
    if verbose:
        logger.setLevel(logging.DEBUG)
    
    try:
        with open(input_file, "r") as file:
            crd = yaml.safe_load(file)
        
        if not crd:
            logger.error("Empty or invalid YAML file")
            return False
            
        logger.info(f"Successfully loaded CRD from {input_file}")
        
        # Extract CRD info with fallbacks
        group, kind, metadata_name, instance_name = get_crd_info(crd, input_file)
        
        # Find schema for all versions
        version_schemas = find_schema(crd)
        
        if not version_schemas:
            logger.error("Could not find valid schema in the given CRD")
            return False
        
        # Use the first available version as default for apiVersion
        default_version = list(version_schemas.keys())[0]
        schema = version_schemas[default_version]
        
        # Extract YAML structure
        spec_structure = extract_yaml_structure(schema)
        
        if not spec_structure:
            # Add dummy fields for empty schema
            logger.warning("Empty schema detected, adding default fields")
            spec_structure = {
                "size": 1,
                "config": {
                    "param": ""
                }
            }
        
        # Generate final YAML structure
        final_yaml = {
            "apiVersion": f"{group}/{default_version}",
            "kind": kind,
            "metadata": {
                "name": instance_name,
                "namespace": "default"
            },
            "spec": spec_structure
        }
        
        # Save YAML file with proper indentation
        with open(output_file, "w") as file:
            yaml.dump(final_yaml, file, default_flow_style=False, indent=2)
        
        logger.info(f"Converted CRD YAML has been saved to '{output_file}'")
        return True
    
    except FileNotFoundError:
        logger.error(f"File not found: {input_file}")
        return False
    except yaml.YAMLError as e:
        logger.error(f"YAML parsing error: {e}")
        return False
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        import traceback
        if verbose:
            logger.debug(traceback.format_exc())
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Kubernetes CRD into a clean YAML structure.")
    parser.add_argument("input_file", nargs="?", help="Path to the CRD YAML file to be converted.")
    parser.add_argument("output_file", nargs="?", help="Path to the output YAML file.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    # Prompt user for input and output file names if not provided via CLI arguments
    input_file = args.input_file or input("📂 Enter the CRD YAML file to convert: ").strip()
    
    if not input_file:
        logger.error("No input file provided. Exiting.")
        sys.exit(1)
    
    # Generate default output filename based on input filename
    default_output_file = os.path.splitext(os.path.basename(input_file))[0] + "-clean.yaml"
    output_file = args.output_file or input(f"💾 Enter the output YAML file name (default: {default_output_file}): ").strip()
    
    if not output_file:
        output_file = default_output_file
    
    success = convert_crd_to_yaml(input_file, output_file, args.verbose)
    if not success:
        sys.exit(1)