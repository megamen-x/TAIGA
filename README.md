<a name="readme-top"></a>  
<img width="100%" src="https://github.com/megamen-x/TAIGA/blob/main/taiga/assets/images/github/main-frame.png" alt="megamen banner">
<div align="center">
  <p align="center">
  </p>

  <p align="center">
    <p></p>
    Создано <strong>megamen</strong>, совместно с <br /> <strong> Министерством природных ресурсов и экологии Российской Федерации</strong>
    <br /><br />
    <a href="https://github.com/megamen-x/TAIGA/issues" style="color: black;">Сообщить об ошибке</a>
    ·
    <a href="https://github.com/megamen-x/TAIGA/discussions/1" style="color: black;">Предложить улучшение</a>
  </p>
</div>

**Содержание:**
- [Проблематика задачи](#title1)
- [Описание решения](#title2)
- [Тестирование решения](#title3)
- [Обновления](#title4)

## <h3 align="start"><a id="title1">Проблематика задачи</a></h3> 
Необходимо создать, с применением технологий искусственного интеллекта, MVP в виде программного решения по регистрации животных на основе данных с фотоловушек.

Ключевые функции программного модуля:
* формирование временных регистраций животных на основе анализа метаданных фотоснимков;
* экспорт результатов обработки в графическом и текстовом виде;
* история обработки фотографий и архивов;
* полная автономность при локальном развертывании;

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>


## <h3 align="start"><a id="title2">Описание решения</a></h3>

**Machine Learning:**

[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-%23EE4C2C.svg?style=for-the-badge&logo=PyTorch&logoColor=white)](https://pytorch.org/)

 - **Общая схема решения:**

<img width="100%" src="https://github.com/megamen-x/TAIGA/blob/main/taiga/assets/images/github/sheme.png" alt="megamen sheme">

 - **Использованные модели:**
    - **```Object Detection```**:
      - YoloV8N;
    - **```Object Classification ```**:
      - EfficientNet;
      - DINOV2.

Ссылки на страницы протестированных моделей:
   - [YoloV8](https://docs.ultralytics.com/models/yolov8/)
   - [EfficientNet](https://github.com/lukemelas/EfficientNet-PyTorch)
   - [DINOV2](https://github.com/facebookresearch/dinov2)
   - [CLIP](https://github.com/openai/CLIP)

**Клиентская часть**

[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)

**Серверная часть**

[![DjangoREST](https://img.shields.io/badge/DJANGO-REST-ff1709?style=for-the-badge&logo=django&logoColor=white&color=ff1709&labelColor=gray)](https://www.django-rest-framework.org/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)



<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>


## <h3 align="start"><a id="title3">Тестирование решения</a></h3> 

Данный репозиторий предполагает следующую конфигурацию тестирования решения:
  
  **```Flutter + Django + ML-models;```**

  <br />

<details>
  <summary> <strong><i> Пункт 1. Запуск Django Rest Framework-сервера:</i></strong> </summary>
  
  - В Visual Studio Code (**Windows-PowerShell activation recommended**) через терминал последовательно выполнить следующие команды:
  
    - Клонирование репозитория:
    ```
    git clone https://github.com/megamen-x/ARTEMIS.git
    ```
    - Создание и активация виртуального окружения (Протестировано на **Python 3.10.10**):
    ```
    cd ./ARTEMIS
    python -m venv .venv
    .venv\Scripts\activate
    ```
    - Уставновка зависимостей (при использовании **CUDA 12.1**):
    ```
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    pip3 install -r requirements.txt
    ```
    - Уставновка зависимостей (при использовании **CPU**):
    ```
    pip3 install torch torchvision torchaudio
    pip3 install -r requirements.txt
    ```
    - После установки зависимостей (5-7 минут):
    ```
    cd artemis-backend/artemis
    python manage.py makemigrations
    python manage.py migrate
    python manage.py runserver
    ```
    - В случае, если не работает стандратная команда makemigrations:
    ```
    python manage.py makemigrations main
    ```
</details> 

<details>
  <summary> <strong><i> Пункт 2. Запуск Flutter приложения на устройстве с Windows или Linux:</i></strong> </summary>
  
  - Перейдите в директорию **```Release```** на вашем устройстве и запустите приложение.

  - Или введите в терминал команду ниже (для Windows):
  
  ```
  cd ./ARTEMIS/artemis-app/Release/artemis.exe
  ```

</details> 

<details>
  <summary> <strong><i> Пункт 3. Работа с Flutter приложением в debug режиме:</i></strong> </summary>
  
  - Если у вас установлен Flutter (и его SDK):
    
    - Запустить ```./artemis/lib/main.dart``` в режиме ```Run and Debug```

  - Иначе:

    - Установить Flutter SDK;
  
    - Склонировать репозиторий себе на компьютер;
  
    ```
    $ git clone -b beta https://github.com/flutter/flutter.git
    ```
    - В конец файла ```~/.bashrc``` добавить 
    ```
    export PATH=<путь к каталогу>/flutter/bin:$PATH
    export ANDROID_HOME=/<путь к каталогу>/android-sdk-linux
    export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
    ```
    - и проверить правильность установки с помощью
    ```
    $ flutter doctor
    ```
    - Запустить ```./artemis/lib/main.dart``` в режиме ```Run and Debug```
</details> 

</br> 

**Аппаратные требования**

| Обеспечение | Требование |
| :----------- | :---------- |
| Платформа, ОС  | Windows (> 8.1), Linux (core > 5.15)    |
| Python | 3.9 or 3.10 (рекомендовано) |
| RAM  | 4 GB или более |
| Свободное место на диске | > 2 GB |

> *Решение может работать без графического ускорителя, однако его наличие будет способствовать увеличению скорости работы использованных моделей.*

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>


## <h3 align="start"><a id="title4">Обновления</a></h3> 

***Все обновления и нововведения будут размещаться здесь!***

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>
