environment                = "staging"
aws_region                 = "us-west-1"
instance_type              = "t2.micro"
min_size                   = 1
max_size                   = 2
desired_capacity           = 1
database_instance_class    = "db.t3.micro"
database_allocated_storage = 30

# Optional: Set these if you have a custom domain and certificate for staging environment

# Restrict access if needed (default allows all)
allowed_cidr_blocks = ["0.0.0.0&#x2F;0"]