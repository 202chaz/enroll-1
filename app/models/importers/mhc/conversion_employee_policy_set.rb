module Importers::Mhc
  class ConversionEmployeePolicySet
     def headers
      [
        "Action",
        "Type of Enrollment",
        "Market",
        "Sponsor Name",
        "FEIN",
        "Issuer Assigned Employer ID",
        "Hire Date",
        "Benefit Begin Date",
        "Plan Name",
        "HIOS Id",
        "(AUTO) Premium Total",
        "Employer Contribution",
        "(AUTO) Employee Responsible Amt",
        "Subscriber SSN",
        "Subscriber DOB",
        "Subscriber Gender",
        "Subscriber Premium",
        "Subscriber First Name",
        "Subscriber Middle Name",
        "Subscriber Last Name",
        "Subscriber Email",
        "Subscriber Phone",
        "Subscriber Address 1",
        "Subscriber Address 2",
        "Subscriber City",
        "Subscriber State",
        "Subscriber Zip",
        "SELF (only one option)",
        "Dep1 SSN",
        "Dep1 DOB",
        "Dep1 Gender",
        "Dep1 First Name",
        "Dep1 Middle Name",
        "Dep1 Last Name",
        "Dep1 Email",
        "Dep1 Phone",
        "Dep1 Address 1",
        "Dep1 Address 2",
        "Dep1 City",
        "Dep1 State",
        "Dep1 Zip",
        "Dep1 Relationship",
        "Dep2 SSN",
        "Dep2 DOB",
        "Dep2 Gender",
        "Dep2 First Name",
        "Dep2 Middle Name",
        "Dep2 Last Name",
        "Dep2 Email",
        "Dep2 Phone",
        "Dep2 Address 1",
        "Dep2 Address 2",
        "Dep2 City",
        "Dep2 State",
        "Dep2 Zip",
        "Dep2 Relationship",
        "Dep3 SSN",
        "Dep3 DOB",
        "Dep3 Gender",
        "Dep3 First Name",
        "Dep3 Middle Name",
        "Dep3 Last Name",
        "Dep3 Email",
        "Dep3 Phone",
        "Dep3 Address 1",
        "Dep3 Address 2",
        "Dep3 City",
        "Dep3 State",
        "Dep3 Zip",
        "Dep3 Relationship",
        "Dep4 SSN",
        "Dep4 DOB",
        "Dep4 Gender",
        "Dep4 First Name",
        "Dep4 Middle Name",
        "Dep4 Last Name",
        "Dep4 Email",
        "Dep4 Phone",
        "Dep4 Address 1",
        "Dep4 Address 2",
        "Dep4 City",
        "Dep4 State",
        "Dep4 Zip",
        "Dep4 Relationship",
        "Dep5 SSN",
        "Dep5 DOB",
        "Dep5 Gender",
        "Dep5 First Name",
        "Dep5 Middle Name",
        "Dep5 Last Name",
        "Dep5 Email",
        "Dep5 Phone",
        "Dep5 Address 1",
        "Dep5 Address 2",
        "Dep5 City",
        "Dep5 State",
        "Dep5 Zip",
        "Dep5 Relationship",
        "Dep6 SSN",
        "Dep6 DOB",
        "Dep6 Gender",
        "Dep6 First Name",
        "Dep6 Middle Name",
        "Dep6 Last Name",
        "Dep6 Email",
        "Dep6 Phone",
        "Dep6 Address 1",
        "Dep6 Address 2",
        "Dep6 City",
        "Dep6 State",
        "Dep6 Zip",
        "Dep6 Relationship",
        "Dep7 SSN",
        "Dep7 DOB",
        "Dep7 Gender",
        "Dep7 First Name",
        "Dep7 Middle Name",
        "Dep7 Last Name",
        "Dep7 Email",
        "Dep7 Phone",
        "Dep7 Address 1",
        "Dep7 Address 2",
        "Dep7 City",
        "Dep7 State",
        "Dep7 Zip",
        "Dep7 Relationship",
        "Dep8 SSN",
        "Dep8 DOB",
        "Dep8 Gender",
        "Dep8 First Name",
        "Dep8 Middle Name",
        "Dep8 Last Name",
        "Dep8 Email",
        "Dep8 Phone",
        "Dep8 Address 1",
        "Dep8 Address 2",
        "Dep8 City",
        "Dep8 State",
        "Dep8 Zip",
        "Dep8 Relationship",
        "Import Status",
        "Import Details"
      ]
    end

    def row_mapping
      [
        :action,
        :ignore,
        :ignore,
        :ignore,
        :fein,
        :ignore,
        :ignore,
        :benefit_begin_date,
        :ignore,
        :hios_id,
        :ignore,
        :ignore,
        :ignore,
        :subscriber_ssn,
        :subscriber_dob,
        :subscriber_gender,
        :subscriber_name_first,
        :subscriber_name_middle,
        :subscriber_name_last,
        :subscriber_email,
        :subscriber_phone,
        :subscriber_address_1,
        :subscriber_address_2,
        :subscriber_city,
        :subscriber_state,
        :subscriber_zip,
        :ignore,
        :dep_1_ssn,
        :dep_1_dob,
        :dep_1_gender,
        :dep_1_name_first,
        :dep_1_name_middle,
        :dep_1_name_last,
        :dep_1_email,
        :dep_1_phone,
        :dep_1_address_1,
        :dep_1_address_2,
        :dep_1_city,
        :dep_1_state,
        :dep_1_zip,
        :dep_1_relationship,
        :dep_2_ssn,
        :dep_2_dob,
        :dep_2_gender,
        :dep_2_name_first,
        :dep_2_name_middle,
        :dep_2_name_last,
        :dep_2_email,
        :dep_2_phone,
        :dep_2_address_1,
        :dep_2_address_2,
        :dep_2_city,
        :dep_2_state,
        :dep_2_zip,
        :dep_2_relationship,
        :dep_3_ssn,
        :dep_3_dob,
        :dep_3_gender,
        :dep_3_name_first,
        :dep_3_name_middle,
        :dep_3_name_last,
        :dep_3_email,
        :dep_3_phone,
        :dep_3_address_1,
        :dep_3_address_2,
        :dep_3_city,
        :dep_3_state,
        :dep_3_zip,
        :dep_3_relationship,
        :dep_4_ssn,
        :dep_4_dob,
        :dep_4_gender,
        :dep_4_name_first,
        :dep_4_name_middle,
        :dep_4_name_last,
        :dep_4_email,
        :dep_4_phone,
        :dep_4_address_1,
        :dep_4_address_2,
        :dep_4_city,
        :dep_4_state,
        :dep_4_zip,
        :dep_4_relationship,
        :dep_5_ssn,
        :dep_5_dob,
        :dep_5_gender,
        :dep_5_name_first,
        :dep_5_name_middle,
        :dep_5_name_last,
        :dep_5_email,
        :dep_5_phone,
        :dep_5_address_1,
        :dep_5_address_2,
        :dep_5_city,
        :dep_5_state,
        :dep_5_zip,
        :dep_5_relationship,
        :dep_6_ssn,
        :dep_6_dob,
        :dep_6_gender,
        :dep_6_name_first,
        :dep_6_name_middle,
        :dep_6_name_last,
        :dep_6_email,
        :dep_6_phone,
        :dep_6_address_1,
        :dep_6_address_2,
        :dep_6_city,
        :dep_6_state,
        :dep_6_zip,
        :dep_6_relationship,
        :dep_7_ssn,
        :dep_7_dob,
        :dep_7_gender,
        :dep_7_name_first,
        :dep_7_name_middle,
        :dep_7_name_last,
        :dep_7_email,
        :dep_7_phone,
        :dep_7_address_1,
        :dep_7_address_2,
        :dep_7_city,
        :dep_7_state,
        :dep_7_zip,
        :dep_7_relationship,
        :dep_8_ssn,
        :dep_8_dob,
        :dep_8_gender,
        :dep_8_name_first,
        :dep_8_name_middle,
        :dep_8_name_last,
        :dep_8_email,
        :dep_8_phone,
        :dep_8_address_1,
        :dep_8_address_2,
        :dep_8_city,
        :dep_8_state,
        :dep_8_zip,
        :dep_8_relationship
      ]
    end

    include ::Importers::RowSet

    def initialize(file_name, o_stream, default_policy_start, py)
      @default_policy_start = default_policy_start
      @plan_year = py
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
    end

    def create_model(record_attrs)
      the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
      case the_action
      when "delete"
        ::Importers::ConversionEmployeePolicyDelete.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
      else
        ::Importers::ConversionEmployeePolicyAction.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
      end
    end
  end
end
