# Дипломный проект Ильин Б

# Что есть в проекте

- Terraform-файлы для создания инфраструктуры
- Ansible playbook для настройки сервера
- установка и запуск Nginx
- папка для скриншотов

## Структура

terraform/ - файлы Terraform  
ansible/ - файлы Ansible  
screenshots/ - скриншоты проекта  

## Запуск Terraform

Перейти в папку terraform

cd terraform

Выполнить команды

terraform init
terraform plan
terraform apply

## Запуск Ansible

Перейти в папку ansible

cd ansible

Запустить playbook

ansible-playbook -i inventory.ini install_nginx.yml


