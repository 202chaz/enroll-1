# frozen_string_literal: true

And /^consumer clicks on pencil symbol next to primary person$/ do
  page.all('.fa-pencil-alt').first.click
end

Then /^consumer should see today date and clicks continue$/ do
  page.find("#applicant_ssn")[:disabled] == "true"
  page.find("input[name='jq_datepicker_ignore_applicant[dob]']")[:disabled] == "true"
end