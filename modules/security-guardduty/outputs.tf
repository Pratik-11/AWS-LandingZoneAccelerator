output "management_detector_id" {
  value = aws_guardduty_detector.management.id
}

output "audit_detector_id" {
  value = aws_guardduty_detector.audit.id
}