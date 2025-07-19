# AWS Architecture Diagram Generator

A comprehensive guide to creating professional AWS architecture diagrams from Terraform code, with a reusable workflow for generating similar diagrams across multiple projects.

## Table of Contents
- [Overview](#overview)
- [Process Steps](#process-steps)
- [Building a Reusable App](#building-a-reusable-app)
- [Implementation Guide](#implementation-guide)
- [File Structure](#file-structure)
- [Example Usage](#example-usage)
- [Future Enhancements](#future-enhancements)

## Overview

This document outlines the systematic approach used to create professional AWS architecture diagrams from Terraform infrastructure code, specifically demonstrated with the AWS Health Notifications project.

### Key Achievements
- ✅ Professional AWS architecture diagram with official service icons
- ✅ Automated analysis of Terraform configurations
- ✅ Proper icon positioning and text alignment
- ✅ Multi-environment support visualization
- ✅ Clear data flow representation

## Process Steps

### 1. Terraform Code Analysis

**Objective**: Understand the infrastructure components and their relationships.

```bash
# Step 1: Analyze main Terraform files
- environments/dev/main.tf
- environments/prod/main.tf
- modules/*/main.tf

# Step 2: Identify key components
- Resource types (AWS services)
- Module dependencies
- Data flow patterns
- Environment configurations
```

**Key Files Analyzed**:
```
├── environments/
│   ├── dev/main.tf
│   └── prod/main.tf
├── modules/
│   ├── eventbridge/main.tf
│   ├── sns/main.tf
│   └── resource_groups/main.tf
└── backend configs
```

### 2. Service Identification

**Services Discovered**:
- AWS Health Dashboard (event source)
- Amazon EventBridge (event routing)
- AWS Lambda (event processing)
- Amazon SNS (notifications)
- Amazon S3 (Terraform state)
- CloudWatch (logging)
- IAM (permissions)
- Resource Groups (organization)

### 3. AWS Icon Asset Integration

**Asset Package Used**: Official AWS Architecture Icons
```
/Asset-Package_02072025.dee42cd0a6eaacc3da1ad9519579357fb546f803/
├── Architecture-Service-Icons_02072025/
│   ├── Arch_Compute/64/Arch_AWS-Lambda_64.svg
│   ├── Arch_App-Integration/64/Arch_Amazon-EventBridge_64.svg
│   ├── Arch_App-Integration/64/Arch_Amazon-Simple-Notification-Service_64.svg
│   ├── Arch_Storage/64/Arch_Amazon-Simple-Storage-Service_64.svg
│   ├── Arch_Management-Governance/64/Arch_Amazon-CloudWatch_64.svg
│   ├── Arch_Management-Governance/64/Arch_AWS-Health-Dashboard_64.svg
│   └── Arch_Security-Identity-Compliance/64/Arch_AWS-Identity-and-Access-Management_64.svg
```

### 4. SVG Diagram Creation

**Design Principles**:
- Official AWS color schemes
- Consistent icon sizing (64px scaled to 0.7)
- Proper text placement below icons
- Clear data flow arrows
- Professional layout with adequate spacing

**Technical Implementation**:
```xml
<!-- Service Box Template -->
<g transform="translate(x, y)">
  <rect width="W" height="H" class="service-box" rx="8"/>
  <!-- AWS Icon (centered, scaled 0.7) -->
  <g transform="translate(centerX, 10) scale(0.7)">
    <rect width="80" height="80" fill="aws-color"/>
    <path d="..." fill="#FFFFFF"/>
  </g>
  <!-- Service Labels (below icon) -->
  <text x="centerX" y="textY" class="service-label">Service Name</text>
  <text x="centerX" y="textY+20" class="description">Description</text>
</g>
```

## Building a Reusable App

### Architecture for Terraform → Diagram Generator

```
terraform-diagram-generator/
├── src/
│   ├── analyzers/
│   │   ├── terraform_parser.py
│   │   ├── aws_service_mapper.py
│   │   └── dependency_analyzer.py
│   ├── generators/
│   │   ├── svg_generator.py
│   │   ├── icon_manager.py
│   │   └── layout_engine.py
│   ├── assets/
│   │   └── aws-icons/
│   └── templates/
│       ├── diagram_template.svg
│       └── service_components.svg
├── config/
│   ├── aws_services.yaml
│   └── layout_rules.yaml
├── tests/
└── examples/
```

### Core Components

#### 1. Terraform Parser (`terraform_parser.py`)

```python
class TerraformParser:
    def __init__(self, project_path):
        self.project_path = project_path
        
    def parse_main_files(self):
        """Parse main.tf files in environments/"""
        
    def parse_modules(self):
        """Parse module configurations"""
        
    def extract_resources(self):
        """Extract AWS resources and their types"""
        
    def identify_data_flows(self):
        """Identify data flow between services"""
        
    def get_environments(self):
        """Detect multi-environment setup"""
```

#### 2. AWS Service Mapper (`aws_service_mapper.py`)

```python
class AWSServiceMapper:
    # Service mapping configuration
    SERVICE_MAPPING = {
        'aws_lambda_function': {
            'service': 'AWS Lambda',
            'icon': 'Arch_AWS-Lambda_64.svg',
            'category': 'compute',
            'color': '#ED7100'
        },
        'aws_sns_topic': {
            'service': 'Amazon SNS',
            'icon': 'Arch_Amazon-Simple-Notification-Service_64.svg',
            'category': 'application-integration',
            'color': '#E7157B'
        },
        # ... more mappings
    }
    
    def map_terraform_to_aws(self, terraform_resources):
        """Map Terraform resources to AWS services"""
        
    def get_service_icon(self, service_name):
        """Get official AWS icon for service"""
```

#### 3. Layout Engine (`layout_engine.py`)

```python
class LayoutEngine:
    def __init__(self, canvas_width=1400, canvas_height=900):
        self.canvas_width = canvas_width
        self.canvas_height = canvas_height
        
    def calculate_positions(self, services, flows):
        """Calculate optimal positions for services"""
        
    def arrange_data_flow(self, source, target):
        """Calculate arrow paths for data flow"""
        
    def apply_layout_rules(self):
        """Apply spacing and alignment rules"""
```

#### 4. SVG Generator (`svg_generator.py`)

```python
class SVGGenerator:
    def __init__(self, aws_icons_path):
        self.icons_path = aws_icons_path
        
    def create_service_component(self, service_info, position):
        """Create SVG component for AWS service"""
        
    def add_data_flow_arrows(self, flows):
        """Add arrows showing data flow"""
        
    def generate_diagram(self, services, flows, layout):
        """Generate complete SVG diagram"""
```

### Configuration Files

#### AWS Services Configuration (`aws_services.yaml`)

```yaml
services:
  lambda:
    terraform_types: 
      - aws_lambda_function
    display_name: "AWS Lambda"
    icon_file: "Arch_AWS-Lambda_64.svg"
    category: "compute"
    color: "#ED7100"
    
  eventbridge:
    terraform_types:
      - aws_cloudwatch_event_rule
      - aws_cloudwatch_event_target
    display_name: "Amazon EventBridge"
    icon_file: "Arch_Amazon-EventBridge_64.svg"
    category: "application-integration"
    color: "#E7157B"

  sns:
    terraform_types:
      - aws_sns_topic
    display_name: "Amazon SNS"
    icon_file: "Arch_Amazon-Simple-Notification-Service_64.svg"
    category: "application-integration"
    color: "#E7157B"
```

#### Layout Rules (`layout_rules.yaml`)

```yaml
layout:
  canvas:
    width: 1400
    height: 900
    
  service_box:
    width: 200
    height: 130
    padding: 20
    border_radius: 8
    
  icon:
    size: 80
    scale: 0.7
    position: "top-center"
    margin_bottom: 20
    
  text:
    title_offset_y: 105
    description_offset_y: 125
    line_height: 15
    
  arrows:
    data_flow:
      color: "#FF6B35"
      width: 4
    service_connection:
      color: "#4A90B8"
      width: 3
```

## Implementation Guide

### Step 1: Setup Project Structure

```bash
mkdir terraform-diagram-generator
cd terraform-diagram-generator

# Create directory structure
mkdir -p src/{analyzers,generators,assets/aws-icons}
mkdir -p config tests examples

# Install dependencies
pip install python-hcl2 pyyaml jinja2 svglib
```

### Step 2: Download AWS Assets

```bash
# Download official AWS Architecture Icons
# Extract to src/assets/aws-icons/
# Organize by service categories
```

### Step 3: Core Implementation

```python
# main.py
from src.analyzers.terraform_parser import TerraformParser
from src.analyzers.aws_service_mapper import AWSServiceMapper
from src.generators.layout_engine import LayoutEngine
from src.generators.svg_generator import SVGGenerator

def generate_diagram(terraform_project_path, output_path):
    # Step 1: Parse Terraform
    parser = TerraformParser(terraform_project_path)
    resources = parser.extract_resources()
    flows = parser.identify_data_flows()
    
    # Step 2: Map to AWS services
    mapper = AWSServiceMapper()
    services = mapper.map_terraform_to_aws(resources)
    
    # Step 3: Calculate layout
    layout_engine = LayoutEngine()
    layout = layout_engine.calculate_positions(services, flows)
    
    # Step 4: Generate SVG
    svg_gen = SVGGenerator('src/assets/aws-icons/')
    diagram = svg_gen.generate_diagram(services, flows, layout)
    
    # Step 5: Save diagram
    with open(output_path, 'w') as f:
        f.write(diagram)

if __name__ == "__main__":
    generate_diagram(
        terraform_project_path="./my-terraform-project",
        output_path="./architecture-diagram.svg"
    )
```

### Step 4: Usage Examples

```bash
# Generate diagram for current project
python main.py --project . --output architecture.svg

# Generate with custom configuration
python main.py --project ./terraform --config custom_layout.yaml --output diagram.svg

# Generate multiple formats
python main.py --project . --formats svg,png,pdf --output diagrams/
```

## File Structure

### Input Structure (Terraform Project)
```
terraform-project/
├── environments/
│   ├── dev/main.tf
│   ├── prod/main.tf
│   └── staging/main.tf
├── modules/
│   ├── vpc/main.tf
│   ├── lambda/main.tf
│   └── rds/main.tf
├── backend.tf
└── variables.tf
```

### Output Structure
```
outputs/
├── architecture-diagram.svg          # Main diagram
├── architecture-diagram.png          # PNG export
├── service-inventory.json             # Discovered services
├── data-flows.json                   # Identified flows
└── layout-coordinates.json           # Positioning data
```

## Example Usage

### Command Line Interface

```bash
# Basic usage
./terraform-diagram-generator --input ./my-terraform-project

# Advanced usage with options
./terraform-diagram-generator \
  --input ./terraform-project \
  --output ./diagrams/architecture.svg \
  --config ./custom-layout.yaml \
  --include-environments dev,prod \
  --exclude-services s3,iam \
  --layout horizontal \
  --title "My Application Architecture"
```

### Python API

```python
from terraform_diagram_generator import DiagramGenerator

# Initialize generator
generator = DiagramGenerator(
    aws_icons_path="./aws-icons/",
    config_path="./config/"
)

# Generate diagram
result = generator.create_diagram(
    terraform_path="./my-project/",
    output_path="./architecture.svg",
    options={
        'title': 'My AWS Architecture',
        'environments': ['dev', 'prod'],
        'layout_style': 'layered',
        'include_data_flows': True,
        'show_environments': True
    }
)

print(f"Generated diagram: {result.output_path}")
print(f"Services found: {len(result.services)}")
print(f"Data flows: {len(result.flows)}")
```

### Configuration Example

```yaml
# custom-config.yaml
diagram:
  title: "Production AWS Architecture"
  canvas:
    width: 1600
    height: 1000
    
  filters:
    include_services: 
      - lambda
      - apigateway
      - dynamodb
      - s3
    exclude_environments:
      - test
      
  layout:
    style: "layered"  # layered, circular, hierarchical
    direction: "left-to-right"
    spacing:
      service: 50
      layer: 100
      
  styling:
    theme: "aws-official"
    show_service_details: true
    show_environment_badges: true
    arrow_style: "curved"
```

## Future Enhancements

### Phase 1: Core Features
- [ ] Support for additional cloud providers (Azure, GCP)
- [ ] Interactive SVG with hover details
- [ ] Cost estimation integration
- [ ] Terraform plan analysis

### Phase 2: Advanced Features
- [ ] Live monitoring integration
- [ ] Security analysis overlay
- [ ] Performance metrics visualization
- [ ] Compliance checking

### Phase 3: Enterprise Features
- [ ] Multi-account/multi-region support
- [ ] Integration with CI/CD pipelines
- [ ] Team collaboration features
- [ ] Version control for diagrams

### Integration Opportunities
- **CI/CD Integration**: Auto-generate diagrams on infrastructure changes
- **Documentation**: Embed in README.md or wiki pages
- **Monitoring**: Link to CloudWatch dashboards
- **Security**: Integrate with AWS Config rules
- **Cost**: Connect to AWS Cost Explorer

## Conclusion

This systematic approach provides a foundation for creating professional AWS architecture diagrams from Terraform code. The reusable application framework enables consistent diagram generation across multiple projects while maintaining AWS standards and best practices.

The key success factors are:
1. **Systematic Terraform analysis** to understand infrastructure
2. **Official AWS assets** for professional appearance
3. **Consistent layout rules** for readability
4. **Automated generation** for maintainability
5. **Configurable options** for flexibility

By following this guide, you can build a robust diagram generation tool that saves time and ensures consistency across your infrastructure documentation.