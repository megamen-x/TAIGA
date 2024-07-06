import json
import os
import random
import shutil
import sys
from pathlib import Path
from zipfile import ZipFile
from rest_framework.views import APIView
from rest_framework import generics, viewsets
from django.http import HttpResponse
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAdminUser, IsAuthenticated
from cv2 import imwrite, imread
from rest_framework.response import Response
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework import generics
import pandas as pd
import plotly
from torchvision.io import read_image
from torchvision.utils import save_image
import plotly.express as px
# import kaleido
import cv2

from .serializers import ImageSerializer
from .models import UploadImageTest, UploadFile

from django.core.files.storage import FileSystemStorage
from django.contrib.auth import update_session_auth_hash
from .serializers import ChangePasswordSerializer, FileSerializer
from django.core.cache import cache

from ultralytics import YOLO, RTDETR
sys.path.append('../ml')
sys.path.append('../ml/utils')
sys.path.append('../ml/configs')
# from ml.cv2_converter import draw_boxes_from_list
# from ml.ensemble import ensemble_boxes, count_classes, count_classes_model
from ml.main import *


def clear_dirs(path_to_directory):
    for i in os.listdir(path_to_directory):
        shutil.rmtree(path_to_directory + i)


def create_dirs(path_to_directory):
    p = Path(path_to_directory)
    if 'archives' not in os.listdir(p):
        os.makedirs(p / 'archives')
    if 'jsons' not in os.listdir(p):
        os.makedirs(p / 'jsons')
    if 'zips' not in os.listdir(p):
        os.makedirs(p / 'zips')
    if 'plots' not in os.listdir(p):
        os.makedirs(p / 'plots')
    if 'labels' not in os.listdir(p):
        os.makedirs(p / 'labels')
    if 'csv' not in os.listdir(p):
        os.makedirs(p / 'csv')


class ListUploadedFiles(generics.ListAPIView):
    queryset = UploadImageTest.objects.all()
    serializer_class = ImageSerializer
    permission_classes = (IsAuthenticated,)

    def get_queryset(self, *args, **kwargs):
        return super().get_queryset(*args, **kwargs).filter(
            user=self.request.user
        )


class ZipViewSet(generics.ListAPIView):
    queryset = UploadFile.objects.all()
    serializer_class = FileSerializer
    permission_classes = (IsAuthenticated, )

    def post(self, request, *args, **kwargs):
        # print(request.FILES['files'])
        # return HttpResponse(status=204)

        file = request.data.get('file')
        if file is None:
            file = request.FILES.get('files')

        if 'media' not in os.listdir('.'):
            os.mkdir('media/')

        create_dirs('media/')

        json_ans = {"data": []}
        # print(file.name)
        FileSystemStorage(location='media/zips/').save(file.name, file)

        with ZipFile('media/zips/' + file.name) as zf:
            print(zf.namelist())
            for name in zf.namelist():
                # print(zf.namelist())
                if os.path.isdir('media/images/' + name):
                    continue
                zf.extract(name, 'media/images/')
                if Path('media/images/' + name).suffix.lower() in ['.jpg', '.jpeg', '.png']:
                    image = UploadFile.objects.create(file=name, user=request.user)
                    with ZipFile('media/archives/file.zip', 'a') as cur_zipfile:
                        cur_zipfile.write('media/images/' + name, 'images/' + os.path.basename(name))

            list_files = [os.path.join('./media/images', el) for el in os.listdir('media/images/')]
            answer = process_images(list_files, by_images=True)
            answer.to_csv('media/csv/answer.csv', index = False)

            with ZipFile('media/archives/file.zip', 'a') as cur_zipfile:
                cur_zipfile.write('media/csv/answer.csv', 'answer.csv')

            for id in answer['id'].unique():
                ans_id = answer[answer['id'] == id]
                res = {'name': [os.path.basename(name) for name in ans_id['link']],
                       'class': list(ans_id['class']),
                       'date_registration': [f'{i} - {j}' for i, j in enumerate(list(ans_id['flag']))],
                       'count': list(a[0] for a in ans_id['count'])}
                json_ans['data'].append(res)

            with open('media/jsons/data.txt', 'w') as outfile:
                 json.dump(json_ans, outfile)

            with ZipFile('media/archives/file.zip', 'a') as cur_zipfile:
                cur_zipfile.write('media/jsons/data.txt', 'data.txt')

        with open('media/archives/file.zip', 'rb') as cur_zipfile:
            response = HttpResponse(cur_zipfile, content_type='application/zip')
            response['Content-Disposition'] = f'attachment; filename=cur_zip_file.zip'

        clear_dirs('media/')
        return response


class FilesViewSet(generics.ListAPIView):
    queryset = UploadFile.objects.all()
    serializer_class = FileSerializer
    permission_classes = (IsAuthenticated, )

    def post(self, request, *args, **kwargs):

        data = request.data.getlist('file')
        if len(data) == 0:
            data = request.FILES.getlist('files')

        if 'media' not in os.listdir('.'):
            os.mkdir('media/')
        create_dirs('media/')

        json_ans = {"data": []}
        for file in data:
            FileSystemStorage(location='media/images/').save(file.name, file)

            with ZipFile('media/archives/file.zip', 'a') as cur_zipfile:
                cur_zipfile.write('media/images/' + file.name, 'images/' + os.path.basename(file.name))

        list_files = [os.path.join('./media/images', el) for el in os.listdir('media/images/')]

        answer = process_images(list_files, by_images=True)
        res = {'name': [os.path.basename(el) for el in answer['link']],
               'class': list(answer['class']),
               'date_registration': [f'{i} - {j}' for i, j in enumerate(list(answer['flag']))],
               'count': list(answer['count'])}
        json_ans['data'].append(res)

        with open('media/jsons/data.txt', 'w') as outfile:
            json.dump(json_ans, outfile)

        answer.to_csv('media/csv/answer.csv', index = False)

        with ZipFile('media/archives/file.zip', 'a') as cur_zipfile:
            cur_zipfile.write('media/jsons/data.txt', 'data.txt')
            cur_zipfile.write('media/csv/answer.csv', 'answer.csv')

        with open('media/archives/file.zip', 'rb') as cur_zipfile:
            response = HttpResponse(cur_zipfile, content_type='application/zip')
            response['Content-Disposition'] = f'attachment; filename=cur_zip_file.zip'

        clear_dirs('media/')
        return response


class ActiveLearningViewSet(generics.ListAPIView):
    queryset = UploadFile.objects.all()
    serializer_class = FileSerializer
    permission_classes = (IsAuthenticated, )

    def post(self, request, *args, **kwargs):

        if 'wrong_detections' not in os.listdir('.'):
            os.mkdir('wrong_detections/')

        latid2label = {
            'Олень - Cervus': '0',
            'Кабарга - Moschus': '1',
            'Косуля - Capreolus': '2',
        }

        file = request.data.get('file')
        if file is None:
            file = request.FILES.get('files')

        if 'wrong_detections' not in os.listdir('.'):
            os.mkdir('wrong_detections/')
        if 'active_learning' not in os.listdir('.'):
            os.mkdir('active_learning/')

        for mode in ['train', 'valid']:
            if mode not in os.listdir('wrong_detections/'):
                os.makedirs('wrong_detections/' + mode)

        for dir in ['Deer', 'Musk Deer', 'Roe Deer']:
            for mode in ['train', 'valid']:
                if dir not in os.listdir('wrong_detections/' + mode):
                    os.makedirs('wrong_detections/' + mode + '/' + dir)

        if Path(file.name).suffix.lower() == '.json':
            FileSystemStorage(location='media/jsons/').save(file.name, file)
            UploadFile.objects.create(file=file.name, user=request.user)

            with open('media/jsons/' + file.name) as f:
                data = json.load(f)
                data = data.get('data')

            if data is None:
                return HttpResponse(status=400)

            for d in data:
                file_name = d['column1']
                id = latid2label[d['column3'][0]]
                label_name = Path(d['column1']).stem + '.txt'
                image = imread('media/images/' + file_name)
                height, width, _ = image.shape

                with open('media/labels/' + label_name, 'r') as f:
                    _, x_min, y_min, x_max, y_max = f.read().replace('\n', '').split()

                    x_min = int(float(x_min) * width)
                    y_min = int(float(y_min) * height)
                    x_max = int(float(x_max) * width)
                    y_max = int(float(y_max) * height)

                    w = x_max - x_min
                    h = y_max - y_min

                    crop = image[y_min + 3:y_min + h - 3,
                           x_min + 3:x_min + w - 3]

                file_path = ''
                if id == '0':
                    file_path = 'Deer/'
                elif id == '1':
                    file_path = 'Musk Deer/'
                elif id == '2':
                    file_path = 'Roe Deer/'
                cv2.imwrite('wrong_detections/' + random.choice(['train/', 'valid/']) + file_path + file_name, crop)

        seed_everything(CFG.seed)

        if CFG.device != 'cuda':
            raise RuntimeError(
                'No CUDA GPUs are available. Make sure CUDA is available and do not use finetune without GPUs')

        vit_backbone, _, preprocess = open_clip.create_model_and_transforms(CFG.model_name, pretrained=False)

        path_load_model = os.path.join('ml', 'best_of_the_best.pt')  # путь до места, где лежит модель
        root_dir = 'wrong_detections/'  # где хранятся данные

        path_to_save_model = 'active_learning/'  # куда сохранить

        train_folder = torchvision.datasets.ImageFolder(root=f'{root_dir}/train', transform=preprocess)
        valid_folder = torchvision.datasets.ImageFolder(root=f'{root_dir}/valid', transform=preprocess)

        train_dataloader = DataLoader(
            train_folder,
            num_workers=4,
            pin_memory=True,
            batch_size=CFG.train_batch_size,
            shuffle=True
        )

        valid_dataloader = DataLoader(
            valid_folder,
            num_workers=4,
            pin_memory=True,
            batch_size=CFG.valid_batch_size,
            shuffle=False
        )

        model = Model(vit_backbone.cpu(), cfg=CFG).to(CFG.device)
        model.load_state_dict(torch.load(path_load_model, map_location=CFG.device))
        model.train()

        optimizer = torch.optim.AdamW(model.get_parameters())
        scaler = torch.cuda.amp.GradScaler(enabled=CFG.autocast)
        steps_per_epoch = math.ceil(len(train_dataloader) / CFG.acc_steps)
        num_training_steps = math.ceil(CFG.n_epochs * steps_per_epoch)
        num_warmup_steps = int(num_training_steps * CFG.n_warmup_steps)

        scheduler = get_cosine_schedule_with_warmup(
            optimizer,
            num_training_steps=num_training_steps,
            num_warmup_steps=num_warmup_steps
        )

        CFG.global_step = 0
        for epoch in range(CFG.n_epochs):
            train(model, train_dataloader, optimizer, scaler, scheduler, epoch)
            score = validate(model, valid_dataloader)
            print(f'Epoch = {epoch + 1}, score: {score}')
            torch.save(model.state_dict(),
                       f'{path_to_save_model}/{CFG.model_name}_{CFG.model_data}_{score}.pth')

            gc.collect()
            torch.cuda.empty_cache()

        return HttpResponse(status=200)


class UpdatePassword(APIView):
    permission_classes = (IsAuthenticated, )

    def put(self, request, *args, **kwargs):
        self.object = self.request.user
        serializer = ChangePasswordSerializer(data=request.data)

        if serializer.is_valid():
            # Check old password
            old_password = serializer.data.get("old_password")
            if not self.object.check_password(old_password):
                return Response({"old_password": ["Wrong password."]},
                                status=status.HTTP_400_BAD_REQUEST)
            # set_password also hashes the password that the user will get
            self.object.set_password(serializer.data.get("new_password"))
            self.object.save()
            return Response(status=status.HTTP_204_NO_CONTENT)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)