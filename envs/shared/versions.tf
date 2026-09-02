terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Backend remoto recomendado para qualquer state que não seja um scratch
  # local. Veja backend.tf.example neste diretório -- copie para backend.tf
  # e preencha os placeholders antes do primeiro "terraform init".
  # backend "s3" {}
}
