provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}


resource "kubernetes_secret" "this" {
  metadata {
    name      = "database"
		namespace = "gitea-testing"
  }

  data = {
    username = var.rds_username
    password = var.rds_password
    db_name  = var.rds_db_name
    host     = "${var.rds_hostname}:3306"
  }

  //type = "kubernetes.io/basic-auth"
  type = "Opaque"
}

resource "kubernetes_storage_class_v1" "this" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
		provisioningMode = "efs-ap"
  }
}

resource "kubernetes_persistent_volume_v1" "this" {
	metadata {
		name = "efs-sc"
		labels = {
      app = "gitea"
      type = "efs"
      pvc = "first"
		}
	}
	spec {
		capacity = {
			storage = "2Gi"
		}
    volume_mode                      = "Filesystem"
		access_modes                     = ["ReadWriteMany", "ReadWriteOnce"]
		storage_class_name               = "efs-sc"
		persistent_volume_reclaim_policy = "Retain"
		persistent_volume_source {
			csi {
				driver = "efs.csi.aws.com"
        volume_handle = "${var.efs_id}::${var.efs_ap_id}"
        #volume_handle = "fs-0f0afa1e2739f5147::fsap-092f0d29859b6f590"
			}
		}
	}
}

/*resource "kubernetes_persistent_volume_claim_v1" "this" {
  metadata {
    name = "efs-claim"
		namespace = "gitea-testing"
		labels = {
      app = "gitea"
      type = "efs"
		}
  }
  spec {
    access_modes = ["ReadWriteMany"]
		storage_class_name = "efs-sc1"
    selector {
      match_labels = {
				pvc = "first"
      }
    }
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    //volume_name = "${kubernetes_persistent_volume_v1.this.metadata.0.name}"
  }
}*/
