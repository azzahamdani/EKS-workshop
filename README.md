# EKS-workshop
Bash scripts to automate the workshop setup and EKS launching

## SetUP

* Open ACloudGuru Session 
* Create an IAM User with the following specs
  1. Name : ``workshop``
  2. Type of Access : password and console
  2. Permission : AdministratorAccess
* Create Cloud9 service and configure it 
  1. Create an Environment ``eksworkshop``
  2. Choose these options 
        “Create a new no-ingress EC2 instance for environment (access via Systems Manager)"
        “t3.small (2GiB RAM + 2CPU)"
        “Amazon Linux 2 (recommended)"
  3. Double check and Create 
* Create IAM Role for your WorkSpace
  1. Go to IAM --> Role --> Create Role
  2. Confirm that AWS service and EC2 are selected, then click Next to view permissions.
  3. Confirm that AdministratorAccess is checked, then click Next: Tags to assign tags.
  4. Take the defaults, and click Next: Review to review
  5. Enter ``eksworkshop-admin`` for the Name, and click Create role.
* Attach the IAM Role to the workspace
  1. Go to EC2 --> Instance --> Cloud9 Instance
  2. Select the instance, then choose Actions / Security / Modify IAM Role
  3. Choose ``eksworkshop-admin`` from the IAM Role drop down, and select Save 
* SetUp
  1. setup the necessary tooling ``setup.sh``