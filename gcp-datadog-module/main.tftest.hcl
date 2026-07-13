mock_provider "google" {
  override_during = plan
}

mock_provider "google-beta" {
  override_during = plan
}

mock_provider "random" {
  override_during = plan
}

mock_provider "time" {
  override_during = plan
}

run "adds_caller_labels_to_the_dataflow_job" {
  command = plan

  variables {
    project_id                = "production-092024"
    subnet_region             = "us-central1"
    vpc_name                  = "prod-core-app"
    subnet_name               = "prod-core-app"
    datadog_api_key           = "fake-datadog-api-key"
    datadog_site_url          = "https://http-intake.logs.us5.datadoghq.com"
    dataflow_temp_bucket_name = "datadog-temp-bucket-production-092024"
    dataflow_job_labels = {
      environment        = "production"
      owner              = "graham"
      project            = "production-092024"
      dataclassification = "confidential"
      application        = "datadog-log-export"
    }
  }

  assert {
    condition = alltrue([
      for key, value in var.dataflow_job_labels :
      google_dataflow_job.pubsub_stream_to_datadog.labels[key] == value
    ])
    error_message = "Caller-provided labels must reach the Dataflow job so its worker VMs inherit them."
  }

  assert {
    condition     = google_dataflow_job.pubsub_stream_to_datadog.labels["dataflow-job-label"] == "datadog_terraform"
    error_message = "Adding caller labels must preserve the module's existing Dataflow label."
  }
}

run "keeps_the_existing_label_by_default" {
  command = plan

  variables {
    project_id                = "development-497017"
    subnet_region             = "us-central1"
    vpc_name                  = "development-core-app"
    subnet_name               = "development-core-app"
    datadog_api_key           = "fake-datadog-api-key"
    datadog_site_url          = "https://http-intake.logs.us5.datadoghq.com"
    dataflow_temp_bucket_name = "datadog-temp-bucket-development-497017"
  }

  assert {
    condition = (
      length(google_dataflow_job.pubsub_stream_to_datadog.labels) == 1 &&
      google_dataflow_job.pubsub_stream_to_datadog.labels["dataflow-job-label"] == "datadog_terraform"
    )
    error_message = "Callers that omit Dataflow job labels must retain the module's current behavior."
  }
}
