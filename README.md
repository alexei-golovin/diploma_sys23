#  Дипломная работа по профессии «Системный администратор» - Алексей Головин SYS-23

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Диплом](#Диплом)

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

---

## Диплом

### Сайт
Все запуски команд проводятся с домашней виртуальной машины с заранее подготовленой конфигурацией.

В папке **/terraform** создаем публичный ключ с помощью команды **ssh-keygen** далее его данные прописываем в заготовленые файлы [meta.yaml](https://github.com/alexei-golovin/diploma_sys23/blob/main/terraform/meta.yaml), [meta1.yaml](https://github.com/alexei-golovin/diploma_sys23/blob/main/terraform/meta1.yaml), [meta2.yaml](https://github.com/alexei-golovin/diploma_sys23/blob/main/terraform/meta2.yaml). Вводим свои данные от **Yandex Cloud** в файлы [variables.tf](https://github.com/alexei-golovin/diploma_sys23/blob/main/terraform/variables.tf), [terraform.tfvars](https://github.com/alexei-golovin/diploma_sys23/blob/main/terraform/terraform.tfvars). Запускаем команду **terraform init**, **terraform apply** подтверждаем свое намериние и ждем пока развернется инфраструктура.

**Успешное завешение terraform**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/terraform_apply.jpg)

**Созданые сервисы Yandex Cloud**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_cloud.jpg)

**Созданые ВМ**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_new_vm.jpg)

**Target Group**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_target.jpg)

**Backend Group**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_backend.jpg)

**HTTP router**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_http_router.jpg)

**Application load balancer**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_load_balancer.jpg)

**Тесты сайта**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/ssh_curl.jpg)
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_curl.jpg)

### Мониторинг

Далее прописываем публичный адрес и имя виртуальной машины **bastion** в файл [/etc/hosts](https://github.com/alexei-golovin/diploma_sys23/blob/main/ansible/hosts). Для установки всех необходимых программ на ВМ запускаем плейбук командой **ansible-playbook -i inventory playbook.yaml** при запросе пароля от публичного ключа вводим его.

**Успешное завешение ansible (p.s. со второй попытки, во время первой провайдер решил что мне сейчас не нужен интернет)**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/ansible_playbook.jpg)

Переходим по адресу http://51.250.33.107/zabbix/ виртуальной машины **zabbix** производим начальную настройку и далее заходим в графический интерфейс для дальнейшей настройки и добавления ВМ.

**Подключенные ВМ и добавленые шаблоны**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_new_zabbix_hosts.jpg)

**Настроеный dashboard для мониторинга ВМ**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_new_zabbix_dashboard.jpg)

### Логи

Переходим по адресу http://51.250.38.40:5601 виртуальной машины **kibana** производим настройку на отправку access.log, error.log nginx в Elasticsearch и проверяем соединение с Elasticsearch.

**Настроеный filebeat**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_new_filebeat.jpg)
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_new_filebeat2.jpg)

**Соединение с elasticsearch**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/browser_new_elasticsearch.jpg)

### Сеть

**VPC**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_vpc.jpg)

**Security Groups**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_security_groups.jpg)

**Подключение к bastion через ssh**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/ssh_new_bastion.jpg)

### Резервное копирование

**Настроеный snapshot дисков ВМ**
![](https://github.com/alexei-golovin/diploma_sys23/blob/main/files/yandex_snapshot.jpg)
