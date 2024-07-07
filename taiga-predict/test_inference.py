import os
import torch
from tqdm import tqdm
from config import MainConfig
from utils import load_detector, load_classificator, open_mapping, extract_crops
from confz import FileSource
from PIL import Image, ExifTags
from datetime import datetime, timedelta
import numpy as np
import pandas as pd
from typing import Union, List
from collections import Counter
from statistics import mode

# Настройка конфига
main_config = MainConfig(config_sources=FileSource(file="config.yml"))
device = 'cuda' if torch.cuda.is_available() else 'cpu'
mapping = open_mapping(path_mapping=main_config.mapping)
detector_config = main_config.detector
classificator_config = main_config.classificator
detector = load_detector(detector_config).to(device)
classificator = load_classificator(classificator_config).to(device)


class RegistrationImage:
    """
    Хранилище данных одной конкретной фотографии
    Хранит в себе путь до фотографии, дату начала регистрации, а также наименование класса (метку) и вероятность данного класса
    """

    def __init__(
            self,
            filepath: str,
            data_registration: datetime,
    ) -> None:
        self.filepath = filepath
        self.data_registration = data_registration
        self.count = 0
        self.species = ''

    def set_species(self, species: str, prob: float, count: int):
        self.species = species
        self.probability = prob
        self.count = count

    def get_species(self) -> str:
        return self.species
    
    def get_count(self) -> int:
        return self.count

    def get_probability(self) -> float:
        return self.probability


class Registration:
    """
    Реализация класса регистрации
    Поля:
    1. data_start_registration - дата начала регистрации
    2. images - хранилище фоток определенной регистрации
    2. max_count - максимальное количество обьектов одного класса внутри одной регистрации
    3. species - класс животного конкретной регистрации
    """

    def __init__(
            self,
            data_start_registration: datetime,
            # count_animals: int,
            # class_animal: str,
            file_path: str
    ) -> None:
        self.data_start_registration = data_start_registration
        # self.max_count = count_animals
        self.images = list()
        self.update(data_start_registration, file_path)
        # self.species = class_animal

    def get_species(self) -> str:
        return self.species

    def set_species(self, class_animal) -> None:
        self.species = class_animal

    def get_max_count(self) -> int:
        return self.max_count

    def set_max_count(self) -> None:
        self.max_count = 1
        for img in self.images:
            self.max_count = max(self.max_count, img.get_count())

    def get_animal_species(self) -> str:
        return self.species

    def get_data_start(self) -> datetime:
        return self.data_start_registration

    def get_data_end(self) -> datetime:
        return self.data_end_registration

    def update(
            self,
            data_end_registration: datetime,
            file_path: str,
    ) -> None:
        self.data_end_registration = data_end_registration
        image = RegistrationImage(filepath=file_path, data_registration=data_end_registration)
        self.images.append(image)
        self.set_duration()

    def get_images(self) -> List[RegistrationImage]:
        return self.images

    def get_duration(self) -> timedelta:
        return self.duration

    def set_duration(self) -> None:
        self.duration = self.data_end_registration - self.data_start_registration


def sorted_files_by_time(files: list) -> tuple:
    """
    "Вытаскивает" информация о времени фиксации животного фотоловушкой с каждой фотографии и сортирует данные по времени
    :param files: список всех фотографий для сортировки
    """
    list_dates = []
    for file in files:
        img = Image.open(file)
        img_exif = img.getexif()
        if img_exif is None:
            print('Sorry, image has no exif data.')
            return []
        else:
            flag = False
            for key, val in img_exif.items():
                if key in ExifTags.TAGS and ExifTags.TAGS[key] == 'DateTime':
                    flag = True
                    datetime_object = datetime.strptime(val, '%Y:%m:%d %H:%M:%S')
                    list_dates.append(datetime_object)
                    break
            if not flag:
                print('Sorry, image has no datetime metadata')
                return []
    combined = list(zip(files, list_dates))
    # Sort the combined list based on the datetime
    sorted_combined = sorted(combined, key=lambda x: x[1])
    listfiles = [item[0] for item in sorted_combined]
    list_dates = [item[1] for item in sorted_combined]
    return listfiles, list_dates


# Обработка изображений
def process_images(listdir, threshold: float = 0.6, by_images: bool = False,
                   save_results_path: str = 'answer.csv', ) -> Union[pd.DataFrame, None]:
    """
    Измененный пайплайн организаторов для обработки данных. Включает в себя все - от классификации до
    алгоритма матчинга кадров в последовательности
    """
    keys = ['name_folder', 'class', 'date_registration_start', 'date_registration_end', 'count']
    if by_images:
        new_keys = ['count', 'link', 'date_registration', 'id']
        keys.extend(new_keys)
    df = pd.DataFrame(columns=keys)
    dirs = os.listdir(listdir)
    for dir in dirs:
        print(dir)
        if os.path.isfile(os.path.join(listdir, dir)):
            continue
        list_files = os.listdir(os.path.join(listdir, dir))
        list_files = [os.path.join(listdir, dir, el) for el in list_files]
        list_files, list_dates = sorted_files_by_time(list_files)
        list_regs_by_time = []
        for file, time in zip(list_files, list_dates):
            if len(list_regs_by_time) == 0:
                list_regs_by_time.append(Registration(file_path=file, data_start_registration=time))
                continue
            if time - list_regs_by_time[-1].get_data_end() <= timedelta(minutes=30):
                list_regs_by_time[-1].update(file_path=file, data_end_registration=time)
            else:
                list_regs_by_time.append(Registration(file_path=file, data_start_registration=time))
        for registration in list_regs_by_time:
            list_images = registration.get_images()
            list_photos = [el.filepath for el in list_images]
            num_packages_det = np.ceil(len(list_photos) / detector_config.batch_size).astype(np.int32)
            with torch.no_grad():
                for i in tqdm(range(num_packages_det), colour="blue"):
                    # Inference detector
                    batch_images_det = list_photos[detector_config.batch_size * i:
                                                detector_config.batch_size * (1 + i)]
                    results_det = detector(
                        batch_images_det,
                        iou=detector_config.iou,
                        conf=detector_config.conf,
                        imgsz=detector_config.imgsz,
                        verbose=False,
                        device=device
                    )

                    if len(results_det) > 0:
                        # Extract crop by bboxes
                        dict_crops = extract_crops(results_det, config=classificator_config)

                        # Inference classificator
                        for img_name, batch_images_cls in dict_crops.items():
                            num_packages_cls = np.ceil(len(batch_images_cls) / classificator_config.batch_size).astype(
                                np.int32)
                            for j in range(num_packages_cls):
                                batch_images_cls = batch_images_cls[classificator_config.batch_size * j:
                                                                    classificator_config.batch_size * (1 + j)]
                                logits = classificator(batch_images_cls.to(device))
                                probabilities = torch.nn.functional.softmax(logits, dim=1)
                                top_p, top_class_idx = probabilities.topk(1, dim=1)
                                top_p = top_p.cpu().numpy().ravel()
                                top_class_idx = top_class_idx.cpu().numpy().ravel()

                                # отбирает кадры классификатора по вероятность верного ответа
                                if top_p[0] > threshold:
                                    class_names = [mapping[top_class_idx[idx]] for idx, _ in enumerate(batch_images_cls)]
                                else:
                                    class_names = ['Empty'] * len(batch_images_cls)
                                
                                registration.images[i].set_species(species=class_names[0], prob=top_p[0],
                                                                count=len(class_names))
                            
            def find_most_frequent_word_with_max_sum(words, values):
                """
                Поикс класса, который наиболее часто встречается и имеет наибольшую суммарную вероятность среди всех объектов
                Необходим для выставления метки всей последовательности по меткам каждый отдельной фотографии в регистрации
                :param words - метки классов
                :param values - вероятности, соответствующие каждый отдельной метке

                Пример расчета:
                another_words = ['Bear', 'Bear']
                another_values = [0.8, 0.71]

                words, score, count = find_most_frequent_word_with_max_sum(another_words, another_values)

                return:
                1. words: Bear
                2. score: 1.51
                3. count: 2
                """
                word_counts = Counter(words)
                max_count = max(word_counts.values())
                most_frequent_words = [word for word, count in word_counts.items() if count == max_count]

                word_sums = {word: 0 for word in most_frequent_words}

                for word, value in zip(words, values):
                    if word in word_sums:
                        word_sums[word] += value

                if word_sums:
                    max_word = max(word_sums, key=word_sums.get)
                    return max_word, word_sums[max_word], max_count
                else:
                    return None, 0, 0

            try:
                # удаляем из рассмотрения класс empty
                all_classes = [el.get_species() for el in registration.get_images() if el.get_species().lower() != 'empty']
                all_probs = [el.get_probability() for el in registration.get_images() if el.get_species().lower() != 'empty']
                result_word, _, _ = find_most_frequent_word_with_max_sum(all_classes, all_probs)
            except:
                result_word = 'Nan'
            # и устанавливаем два параметра для регистрации
            # класс животного на регистрации и максимальное количество животных в последовательности
            registration.set_species(class_animal=result_word)
            registration.set_max_count()
        most_common_dir_species = mode([registration.get_species() for registration in list_regs_by_time if registration.get_species() != 'Nan'])
        # и крайне странным образом (у нас было всего 3 дня, простите)
        # сохраняем данные о каждой регистрации в формате как в sample_submission.csv
        for registration in list_regs_by_time:
            if registration.get_species() == 'Nan':
                registration.set_species(most_common_dir_species)
        for i, registration in enumerate(list_regs_by_time):
            new_row = {
                'name_folder': str(dir), 'class': registration.get_species(),
                'date_registration_start': registration.get_data_start().strftime('%Y-%m-%d %H:%M:%S'),
                'date_registration_end': registration.get_data_end().strftime('%Y-%m-%d %H:%M:%S'),
                'count': registration.get_max_count()}
            if by_images:
                for image in registration.get_images():
                    new_row['date_registration'] = image.data_registration.strftime('%Y-%m-%d %H:%M:%S')
                    new_row['count'] = image.count,
                    new_row['link'] = image.filepath
                    new_row['id'] = str(i + 1)
                    df.loc[len(df)] = new_row
            else:
                df.loc[len(df)] = new_row

    # сортируем табличку по времени регистрации и сохраняем данные регистраций
    df = df.sort_values(by=['name_folder', 'date_registration' if by_images else 'date_registration_start'])
    df.to_csv(save_results_path, index=False)
    return df


if __name__ == '__main__':
    answer = process_images('test_data_Minprirodi\\traps', by_images=False)
