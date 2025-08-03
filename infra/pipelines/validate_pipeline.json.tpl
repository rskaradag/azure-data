{
  "name": "${pipeline_name}",
  "properties": {
    "activities": [
      {
        "name": "RunNotebookValidation",
        "type": "SynapseNotebook",
        "dependsOn": [],
        "policy": {
          "timeout": "1.00:00:00",
          "retry": 1,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "userProperties": [],
        "notebook": {
          "referenceName": "${notebook_name}",
          "type": "NotebookReference"
        },
        "compute": {
          "referenceName": "${spark_pool_name}",
          "type": "BigDataPoolReference"
        }
      }
    ],
    "annotations": []
  },
  "type": "Microsoft.Synapse/workspaces/pipelines"
}
