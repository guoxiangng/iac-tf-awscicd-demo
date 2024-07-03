FROM --platform=linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04_stable

LABEL authors = "guo.xiang.ng1@ncs.com.sg"
LABEL authors.lastupdatedate = "26/6/2024"

USER root

RUN apt-get update -y && apt-get install unzip -y && apt-get install wget -y && apt-get install git -y && apt-get -y install curl && apt-get -y install jq 

RUN apt-get install python3 -y && apt-get install python3-pip -y

# RUN python3 -m pip install --upgrade pip --break-system-packages

# install terraform 1.8.5 (latest at 26/6/2024)
RUN wget https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip --no-check-certificate
RUN unzip terraform_1.8.5_linux_amd64.zip
RUN mv terraform /usr/local/bin/

# install TFLINT
RUN curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && \
unzip tflint.zip && \
rm tflint.zip
RUN mv tflint /usr/bin/

# install checkov
RUN pip3 install --no-cache-dir checkov --break-system-packages

# install TFSEC
RUN curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && \
chmod +x tfsec
RUN mv tfsec /usr/bin/

# install OPA v0.65 (latest at 26/06/2024 )
RUN curl -k -L -o opa https://openpolicyagent.org/downloads/v0.65.0/opa_linux_amd64_static 
RUN chmod 755 ./opa
RUN mv opa /usr/bin/