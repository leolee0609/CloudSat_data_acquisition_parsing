from django.shortcuts import render, redirect, reverse
from .forms import JsonInputForm
from django.http import HttpResponse
import json


def json_form(request):
    if request.method == 'POST':
        form = JsonInputForm(request.POST)
        if form.is_valid():
            data = {
                "jobId": form.cleaned_data['jobId'],
                "jobType": form.cleaned_data['jobType'],
                "dateRange": [
                    form.cleaned_data['dateRangeStart'].strftime('%Y-%m-%dT%H:%M:%S'),
                    form.cleaned_data['dateRangeEnd'].strftime('%Y-%m-%dT%H:%M:%S')
                ],
                "filterCriteria": {}
            }

            # New logic to handle code input
            code_type = form.cleaned_data['code_type']
            if code_type:  # Checks if code_type is not None and not empty
                data['filterCriteria'][code_type] = form.cleaned_data['code']

            # File saving remains the same
            file_path = f'/Users/liding/Documents/Documents/uwaterloo/research/CloudSat/CloudSatWebProjects/backendMainProgramPython/requests/{data["jobId"]}.json'
            with open(file_path, 'w') as json_file:
                json.dump(data, json_file, indent=4)

            return redirect(reverse('job-success', kwargs={'job_id': data['jobId']}))
    else:
        form = JsonInputForm()
    return render(request, 'CloudSatDataQuery/form.html', {'form': form})


def load_job_data(request, job_id):
    try:
        filepath = f'/Users/liding/Documents/Documents/uwaterloo/research/CloudSat/CloudSatWebProjects/backendMainProgramPython/jobsInfo/{job_id}_parsing_task.json'
        with open(filepath, 'r') as file:
            job_data = json.load(file)
        return render(request, 'CloudSatDataQuery/success.html', {'job_data': job_data})
    except FileNotFoundError:
        return HttpResponse("File not found.", status=404)
