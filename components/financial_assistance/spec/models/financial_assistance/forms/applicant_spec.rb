# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::Applicant, type: :model, dbclean: :after_each do
  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: 'draft',
                      effective_date: Date.today)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: Date.today - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let!(:spouse_applicant) do
    appl = FactoryBot.create(:applicant,
                             application: application,
                             dob: Date.today - 40.years,
                             family_member_id: BSON::ObjectId.new)
    application.ensure_relationship_with_primary(appl, 'spouse')
    appl
  end

  let(:params) do
    { first_name: input_applicant.first_name,
      last_name: input_applicant.last_name,
      middle_name: '',
      name_sfx: '',
      dob: input_applicant.dob.strftime("%Y-%m-%d"),
      ssn: input_applicant.ssn,
      gender: input_applicant.gender,
      is_applying_coverage: 'true',
      us_citizen: 'true',
      naturalized_citizen: 'false',
      indian_tribe_member: 'false',
      tribal_id: '',
      is_incarcerated: 'false',
      relationship: relationship,
      is_consumer_role: 'true',
      is_temporarily_out_of_state: '0',
      is_homeless: '0',
      no_ssn: '0',
      addresses_attributes: { :'0' => { kind: 'home',
                                        address_1: '',
                                        address_2: '',
                                        city: '',
                                        state: '',
                                        zip: '',
                                        _destroy: 'false'},
                              :'1' => { kind: 'mailing',
                                        address_1: '',
                                        address_2: '',
                                        city: '',
                                        state: '',
                                        zip: '',
                                        _destroy: 'false'}},
      ethnicity: ['', '', '', '', '', '', '']}
  end

  before do
    @applicant_form = described_class.new(params)
    @applicant_form.application_id = application.id
    @applicant_form.applicant_id = input_applicant.id
    @applicant_form.relationship_validation
  end

  context 'relationship_validation' do
    context 'applicant spouse update' do
      let(:input_applicant) {spouse_applicant}
      let(:relationship) {'spouse'}

      it 'should not add any errors when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to be_empty
      end
    end

    context 'with spouse and child as spouse' do
      let!(:child_applicant) do
        appl = FactoryBot.create(:applicant,
                                 application: application,
                                 dob: Date.today - 40.years,
                                 family_member_id: BSON::ObjectId.new)
        application.ensure_relationship_with_primary(appl, 'child')
        appl
      end

      let(:input_applicant) {child_applicant}
      let(:relationship) {'spouse'}

      it 'should add error when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to include('can not have multiple spouse or life partner')
      end
    end

    context 'with more than one spouse' do
      let!(:spouse_applicant2) do
        appl = FactoryBot.create(:applicant,
                                 application: application,
                                 dob: Date.today - 40.years,
                                 family_member_id: BSON::ObjectId.new)
        application.ensure_relationship_with_primary(appl, 'spouse')
        appl
      end

      let(:input_applicant) {spouse_applicant2}
      let(:relationship) {'child'}

      it 'should add error when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to include('can not have multiple spouse or life partner')
      end
    end
  end
end
