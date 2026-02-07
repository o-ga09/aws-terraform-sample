# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_s3_bucket
      prefix  = var.access_logs_s3_prefix
      enabled = true
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-alb"
      Environment = var.environment
    },
    var.tags
  )
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = var.target_group_config.port
  protocol    = var.target_group_config.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.target_group_config.health_check_path
    interval            = var.target_group_config.health_check_interval
    timeout             = var.target_group_config.health_check_timeout
    healthy_threshold   = var.target_group_config.healthy_threshold
    unhealthy_threshold = var.target_group_config.unhealthy_threshold
    matcher             = var.target_group_config.matcher
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = merge(
    {
      Name        = "${var.project_name}-tg"
      Environment = var.environment
    },
    var.tags
  )
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = !var.enable_https ? aws_lb_target_group.main.arn : null
  }
}

# HTTPS Listener (optional)
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
