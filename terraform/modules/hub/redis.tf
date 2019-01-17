resource "aws_elasticache_replication_group" "policy_session_store" {
  automatic_failover_enabled    = true
  availability_zones            = ["${local.azs}"]
  replication_group_id          = "${var.deployment}-policy"
  replication_group_description = "Replication group for the ${var.deployment} Policy session store"
  maintenance_window            = "tue:02:00-tue:04:00"
  node_type                     = "${var.redis_cache_size}"
  number_cache_clusters         = "${var.number_of_availability_zones}"
  parameter_group_name          = "${aws_elasticache_parameter_group.policy_session_store.name}"
  security_group_ids            = ["${aws_security_group.policy_redis.id}"]
  subnet_group_name             = "${aws_elasticache_subnet_group.policy_session_store.name}"
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  port                          = 6379
}

resource "aws_elasticache_subnet_group" "policy_session_store" {
  name       = "${var.deployment}-policy"
  subnet_ids = ["${aws_subnet.internal.*.id}"]
}

resource "aws_elasticache_parameter_group" "policy_session_store" {
  name   = "${var.deployment}-policy"
  family = "redis5.0"
}

resource "aws_security_group" "policy_redis" {
  name        = "${var.deployment}-policy-redis"
  description = "${var.deployment}-policy-redis"
  vpc_id      = "${aws_vpc.hub.id}"
}
