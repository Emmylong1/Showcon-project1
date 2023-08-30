# Use the data source to fetch the default parameter group associated with your engine version.
data "aws_rds_engine_version" "default" {
  engine  = "mysql"
  version = "8.0.33"  # Specify your engine version here
}

# Create your custom parameter group based on the default one.
resource "aws_db_parameter_group" "custom_parameters_group" {
  name        = "custom-rds-parameters"
  family      = data.aws_rds_engine_version.default.parameter_group_family
  description = "My Custom MySQL RDS Parameter Group"

  parameter {
    name                 = "rds_parameters"
    value                = "10"
    apply_method         = "immediate"
  }
}

/*
# Add custom parameters to the custom parameter group.
resource "aws_db_parameter_group_parameter" "custom_parameters" {
  name                 = "custom_parameter_name"
  value                = "10"
  apply_method         = "immediate"
  parameter_group_name = aws_db_parameter_group.custom_parameters_group.name
}

# Add parameters from the default parameter group.
resource "aws_db_parameter_group_parameter" "default_parameters" {
  name                 = "rds_parameters"
  value                = "10"
  apply_method         = "immediate"
  parameter_group_name = aws_db_parameter_group.custom_parameters_group.name
}
*/