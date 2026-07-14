# Anglus Security Research

## Legal Notice

This material is provided exclusively for educational, academic, and information security research purposes.

Its purpose is to encourage responsible study of software architecture, license protection, defensive reverse engineering, vulnerability analysis, and compliance best practices. This content must not be used to violate terms of service, bypass licensing mechanisms, access paid features without authorization, or harm third parties.

## Permitted Use

This project may be used for:

* technical study in owned or authorized environments;
* defensive security analysis;
* documentation of software protection concepts;
* academic research and professional learning;
* improvement of audit, compliance, and system protection processes.

## User Responsibility

Before testing, analyzing, or modifying any third-party software, make sure you have explicit authorization from the owner or vendor.

Any misuse of this material is the sole responsibility of the user. The authors, contributors, and maintainers are not responsible for damages, losses, contractual violations, legal breaches, or any consequences resulting from improper use.

## Compliance

This project does not encourage piracy, license violation, unauthorized commercial use, unauthorized software distribution, or any activity that violates laws, agreements, or vendor policies.

Use this content ethically, responsibly, and with respect for intellectual property.

---

## Download [Surveillance Station](https://archive.synology.com/download/Package/SurveillanceStation)

---
### Crack License
- Online:
```shell
# 1. 普通 Normal
curl -fsSL https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh | bash
# 2. 使用github代理(可自行更换代理, 注意结尾的/) Using github proxy (Please replace the proxy address yourself)
export GPROXY=https://gh-proxy.org/
curl -fsSL ${GPROXY:-}https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh  | bash
export GPROXY=
# 3. 使用 http(s)/socks5 代理(请自行更换代理地址) Using http(s)/socks5 proxy (Please replace the proxy address yourself)
export CPROXY=http://username:password@192.168.20.1:7890
curl -fsSL -x ${CPROXY:+-x ${CPROXY}} https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh  | bash
export CPROXY=
```
- Offline:
```shell
# 1. Download https://github.com/ohyeah521/Surveillance-Station/archive/refs/heads/main.zip
# 2. Unload to your DSM system.
unzip Surveillance-Station-main.zip
cd Surveillance-Station-main
chmod +x activated.sh
./activated.sh 
```

---
### Restore License
- Online:
```shell
# 1. 普通 Normal
curl -fsSL https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh | bash -s -- -r
# 2. 使用 github 代理(可自行更换代理, 注意结尾的/) Using github proxy (Please replace the proxy address yourself)
export GPROXY=https://gh-proxy.org/
curl -fsSL ${GPROXY:-}https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh | bash -s -- -r
export GPROXY=
# 3. 使用 http(s)/socks5 代理(请自行更换代理地址) Using http(s)/socks5 proxy (Please replace the proxy address yourself)
export CPROXY=http://username:password@192.168.20.1:7890
curl -fsSL ${CPROXY:+-x ${CPROXY}} https://raw.githubusercontent.com/ohyeah521/Surveillance-Station/main/activated.sh | bash -s -- -r
export CPROXY=
```
- Offline:
```shell
# 1. Download https://github.com/ohyeah521/Surveillance-Station/archive/refs/heads/main.zip
# 2. Unload to your DSM system.
unzip Surveillance-Station-main.zip
cd Surveillance-Station-main
chmod +x activated.sh
./activated.sh -r
```

---
