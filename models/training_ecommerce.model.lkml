connection: "bigquery_public_data_looker"

# include all the views
include: "/views/*.view"
include: "/z_tests/*.lkml"
include: "/**/*.dashboard"

datagroup: daily_datagroup {
  sql_trigger: SELECT FORMAT_TIMESTAMP('%F',
    CURRENT_TIMESTAMP(), 'America/Los_Angeles') ;;
  max_cache_age: "24 hours"
}

label: "E-Commerce Training"

explore: order_items {
  join: users {
    type: left_outer
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
  }

  join: inventory_items {
    type: left_outer
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
    relationship: many_to_one
  }

  join: products {
    type: left_outer
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }

  join: distribution_centers {
    type: left_outer
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
    relationship: many_to_one
  }
}

explore: events {
  join: event_session_facts {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_facts.session_id} ;;
    relationship: many_to_one
  }
  join: event_session_funnel {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_funnel.session_id} ;;
    relationship: many_to_one
  }
  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}

explore: incremental_pdt {}


explore: +order_items {
  label: "Order Items - Aggregate Sales"
  aggregate_table: aggregate_sales {
    query: {
      dimensions: [order_items.created_date, users.state]
      measures: [order_items.average_sale_price,
        order_items.total_revenue]
    }
    materialization: {
      datagroup_trigger: daily_datagroup
      increment_key: "created_date"
      increment_offset: 3
    }
  }
}

explore: aggregated_orders {
  from: order_items
  label: "Aggregated Sales"
  join: users {
    type: left_outer
    sql_on: ${aggregated_orders.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
  aggregate_table: aggregate_sales {
    query: {
      dimensions: [aggregated_orders.created_date,
        users.state]
      measures: [aggregated_orders.average_sale_price,
        aggregated_orders.total_revenue]
    }
    materialization: {
      datagroup_trigger: daily_datagroup
      increment_key: "created_date"
      increment_offset: 3
    }
  }
}
