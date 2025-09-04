environment                = "production"
aws_region                 = "us-west-1"
instance_type              = "t2.small"
min_size                   = 2
max_size                   = 5
desired_capacity           = 2
database_instance_class    = "db.t3.small"
database_allocated_storage = 100

# Optional: Set these if you have a custom domain and certificate for production environment

# Restrict access if needed (default allows all)
allowed_cidr_blocks = ["0.0.0.0&#x2F;0"]