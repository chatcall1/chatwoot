require 'rails_helper'

RSpec.describe Whatsapp::TemplateVariableValidator do
  context 'with named parameters' do
    subject(:validator) { described_class.new('parameter_format' => 'NAMED') }

    it 'accepts lowercase names and their examples' do
      expect do
        validator.validate_text!('Hello {{customer_name}}.', max_length: 100, required: true, label: 'Body')
        validator.validate_examples!('Hello {{customer_name}}.', { 'customer_name' => 'Jane' }, 'Body')
      end.not_to raise_error
    end

    it 'rejects names containing digits' do
      expect do
        validator.validate_text!('Hello {{customer_1}}', max_length: 100, required: true, label: 'Body')
      end.to raise_error(Whatsapp::TemplateCreationService::ValidationError, 'Body contains an invalid variable')
    end

    it 'rejects duplicate names' do
      expect do
        validator.validate_text!('Hi {{name}}, bye {{name}}.', max_length: 100, required: true, label: 'Body')
      end.to raise_error(Whatsapp::TemplateCreationService::ValidationError, 'Body named variables must be unique')
    end
  end

  context 'with positional parameters' do
    subject(:validator) { described_class.new('parameter_format' => 'POSITIONAL') }

    it 'rejects non-sequential parameters' do
      expect do
        validator.validate_text!('Hello {{1}} and {{3}}.', max_length: 100, required: true, label: 'Body')
      end.to raise_error(Whatsapp::TemplateCreationService::ValidationError, 'Body variables must be sequential')
    end
  end
end
