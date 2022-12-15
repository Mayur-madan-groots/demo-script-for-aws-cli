#!/bin/bash/

echo "checking connection"

if
        aws ec2 describe-vpcs >/dev/null 2>&1; then
  echo -e "\nTest connection to AWS was successful.";
else
  echo -e "\nERROR: test connection to AWS failed. Please check the AWS keys.";
  exit 1;
fi


#Declaring Variables

vpc_id=vpc-e332298b
subnet_id=subnet-d85f5fb0
ami_id=ami-07ffb2f4d65357b42
instancename=alchemy-ec2dvpc1
sgname=alchemy-sgroupdvpc1


echo "creating security group"
#creating SG
aws ec2 create-security-group --group-name $sgname --description "created for alchemy-poc"  --vpc-id "$vpc_id"  --output text >  /dev/null 2>&1


#retrieving the group-id of the security group created
sgid=`aws ec2 describe-security-groups  --query "SecurityGroups[].GroupId" --filters "Name=group-name,Values=$sgname" | sed -n 2p | tr -d \"`


#Adding the inbound rules to the security group created
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 22 --cidr 0.0.0.0/0  >  /dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 80 --cidr 0.0.0.0/0  >  /dev/null 2>&1

echo "security group created"

#Launching the instance"



echo "creating ec2"

aws ec2 run-instances --image-id ami-07ffb2f4d65357b42 --count 1 --instance-type t3.micro  --security-group-ids $sgid --subnet-id $subnet_id   --user-data file://userdata.txt   --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":10,\"DeleteOnTermination\":true}}]"  --tag-specification "ResourceType=instance,Tags=[{Key=Name,Value=$instancename}]" --output text >  /dev/null 2>&1


#printing ip,id and port
echo -e "\033[0;31m'printing instance id,public ip and allowed port"

aws ec2 describe-instances  --filters Name=tag:Name,Values=$instancename   --query 'Reservations[*].Instances[*].{id:InstanceId,publicip:PublicIpAddress,PrivateIpAddress:PrivateIpAddress}'  --output table &&  aws ec2 describe-security-groups     --group-ids $sgid  --query "SecurityGroups[].IpPermissions[].{rule1:FromPort,rule2:ToPort}"   --output table

#terminating ec2
echo "terminating ec2 after 10 sec"

sleep 10s

echo "terminating ec2"

aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --filters "Name=tag:Name,Values=$instancename" --output text) --output text >  /dev/null 2>&1

echo "ec2 terminated
"
echo "6mins to delete security group"
sleep 6m

echo "deleting Security group"
aws ec2 delete-security-group --group-id $sgid >  /dev/null 2>&1

echo "security group deleted"


