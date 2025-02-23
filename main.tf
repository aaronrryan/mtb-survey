terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "mtb_survey" {
  metadata {
    name = "mtb-survey"
  }
}

resource "kubernetes_deployment" "mtb_survey" {
  metadata {
    name      = "mtb-survey"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
    annotations = {
      "app.version" = var.app_version
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mtb-survey"
      }
    }

    template {
      metadata {
        labels = {
          app = "mtb-survey"
        }
      }

      spec {
        container {
          image = "aaronrryan/mtb-survey-frontend:latest"
          name  = "mtb-survey"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mtb_survey" {
  metadata {
    name      = "mtb-survey"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    selector = {
      app = "mtb-survey"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

// Add MySQL deployment
resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.mysql_root_password
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "mtb_survey"
          }

          port {
            container_port = 3306
          }

          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
        }

        volume {
          name = "mysql-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

// Add MySQL service
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
}

// Add Flask API deployment
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "flask-api"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flask-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask-api"
        }
      }

      spec {
        container {
          name  = "flask-api"
          image = var.api_image

          env {
            name  = "DB_HOST"
            value = "mysql"
          }

          env {
            name  = "DB_USER"
            value = "root"
          }

          env {
            name  = "DB_PASSWORD"
            value = var.mysql_root_password
          }

          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

// Add Flask API service
resource "kubernetes_service" "api" {
  metadata {
    name      = "flask-api"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    selector = {
      app = "flask-api"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "ClusterIP"
  }
}

// Add PVC for MySQL
resource "kubernetes_persistent_volume_claim" "mysql_pvc" {
  metadata {
    name      = "mysql-pvc"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

// Add ConfigMap for NGINX controller
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-ingress-controller-config"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
  }

  data = {
    "use-forwarded-headers" = "true"
    "proxy-body-size"      = "10m"
    "client-max-body-size" = "10m"
  }
}

resource "kubernetes_ingress_v1" "mtb_survey" {
  metadata {
    name      = "mtb-survey-ingress"
    namespace = kubernetes_namespace.mtb_survey.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "10m"
      "nginx.ingress.kubernetes.io/use-forwarded-headers" = "true"
      "nginx.ingress.kubernetes.io/enable-real-ip" = "true"
    }
  }

  spec {
    rule {
      host = "mtb.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.mtb_survey.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        path {
          path = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}