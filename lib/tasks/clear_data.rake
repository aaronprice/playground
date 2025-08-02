namespace :data do
  desc "Delete all customers, purchase orders, and purchase order lines from the database"
  task clear_all: :environment do
    puts "Starting data cleanup..."

    # Count records before deletion for reporting
    customer_count = Customer.count
    po_count = PurchaseOrder.count
    po_line_count = PurchaseOrderLine.count

    puts "Found #{customer_count} customers, #{po_count} purchase orders, and #{po_line_count} purchase order lines"

    if customer_count == 0 && po_count == 0 && po_line_count == 0
      puts "No data to delete. Database is already empty."
      return
    end

    # Confirm deletion in non-production environments
    unless Rails.env.production?
      print "Are you sure you want to delete all this data? (y/N): "
      confirmation = STDIN.gets.chomp.downcase

      unless confirmation == 'y' || confirmation == 'yes'
        puts "Operation cancelled."
        return
      end
    end

    begin
      # Use transaction for atomicity
      ActiveRecord::Base.transaction do
        # Delete all customers - this will cascade to purchase orders and lines
        # due to dependent: :destroy associations
        deleted_customers = Customer.destroy_all

        puts "Successfully deleted #{deleted_customers.count} customers"
        puts "All related purchase orders and purchase order lines have been deleted via cascade"
      end

      # Verify deletion
      remaining_customers = Customer.count
      remaining_pos = PurchaseOrder.count
      remaining_po_lines = PurchaseOrderLine.count

      puts "Verification: #{remaining_customers} customers, #{remaining_pos} purchase orders, #{remaining_po_lines} purchase order lines remaining"

      if remaining_customers == 0 && remaining_pos == 0 && remaining_po_lines == 0
        puts "✅ Data cleanup completed successfully!"
      else
        puts "⚠️  Warning: Some data may still remain. Please check manually."
      end

    rescue => e
      puts "❌ Error during data cleanup: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      raise e
    end
  end

  desc "Delete all customers, purchase orders, and purchase order lines without confirmation (use with caution)"
  task clear_all_force: :environment do
    puts "Force deleting all data without confirmation..."

    begin
      ActiveRecord::Base.transaction do
        deleted_customers = Customer.destroy_all
        puts "Deleted #{deleted_customers.count} customers and all related records"
      end

      puts "✅ Force data cleanup completed!"
    rescue => e
      puts "❌ Error during force data cleanup: #{e.message}"
      raise e
    end
  end
end