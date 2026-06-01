# -------------------------
# Disk snapshots
# -------------------------

resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  name        = "diplom-daily-snapshots"
  description = "Daily snapshots for diploma project virtual machine boot disks"

  schedule_policy {
    expression = "0 3 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "Daily snapshot created by Terraform snapshot schedule"

    labels = {
      project = "diplom"
      type    = "daily"
    }
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web_1.boot_disk[0].disk_id,
    yandex_compute_instance.web_2.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.elasticsearch.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id
  ]
}

output "snapshot_schedule_id" {
  description = "Yandex Cloud snapshot schedule ID"
  value       = yandex_compute_snapshot_schedule.daily_snapshots.id
}
