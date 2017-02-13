# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Job::Evaluator do
  describe '.only_if' do
    context 'with eq' do
      it 'compares integers' do
        expect(described_class.only_if('1 eq 1', {})).to be true
        expect(described_class.only_if('1 eq 0', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 eq 1.0', {})).to be true
        expect(described_class.only_if('1.0 eq 0.1', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% eq 90%', {})).to be true
        expect(described_class.only_if('90% eq 100%', {})).to be false
      end
    end

    context 'with ==' do
      it 'compares integers' do
        expect(described_class.only_if('1 == 1', {})).to be true
        expect(described_class.only_if('1 == 0', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 == 1.0', {})).to be true
        expect(described_class.only_if('1.0 == 0.1', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% == 90%', {})).to be true
        expect(described_class.only_if('90% == 100%', {})).to be false
      end

      it 'compares strings' do
        expect(described_class.only_if("'foo' == 'foo'", {})).to be true
        expect(described_class.only_if("'foo' == 'bar'", {})).to be false
        expect(described_class.only_if("'foo' == 'FOO'", {})).to be true
        expect(described_class.only_if("'foo' == 'BAR'", {})).to be false
        expect(described_class.only_if("'this is a string' == 'this is a string'", {})).to be true
        expect(described_class.only_if("'this is a string' == 'THIS IS A STRING'", {})).to be true
        expect(described_class.only_if("'this is a string' == 'this is a test'", {})).to be false
        expect(described_class.only_if("'this is a string' == 'THIS IS A TEST'", {})).to be false
      end

      it 'compares empty strings' do
        expect(described_class.only_if("'' == ''", {})).to be true
        expect(described_class.only_if("'foo' == ''", {})).to be false
        expect(described_class.only_if("'' == 'foo'", {})).to be false
      end
    end

    context 'with ===' do
      it 'compares strings' do
        expect(described_class.only_if("'foo' === 'foo'", {})).to be true
        expect(described_class.only_if("'foo' === 'bar'", {})).to be false
        expect(described_class.only_if("'foo' === 'FOO'", {})).to be false
        expect(described_class.only_if("'foo' === 'BAR'", {})).to be false
        expect(described_class.only_if("'this is a string' === 'this is a string'", {})).to be true
        expect(described_class.only_if("'this is a string' === 'THIS IS A STRING'", {})).to be false
        expect(described_class.only_if("'this is a string' === 'this is a test'", {})).to be false
        expect(described_class.only_if("'this is a string' === 'THIS IS A TEST'", {})).to be false
      end

      it 'compares empty strings' do
        expect(described_class.only_if("'' === ''", {})).to be true
        expect(described_class.only_if("'foo' === ''", {})).to be false
        expect(described_class.only_if("'' === 'foo'", {})).to be false
      end
    end

    context 'with ne' do
      it 'compares integers' do
        expect(described_class.only_if('1 ne 1', {})).to be false
        expect(described_class.only_if('1 ne 0', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 ne 1.0', {})).to be false
        expect(described_class.only_if('1.0 ne 0.1', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% ne 90%', {})).to be false
        expect(described_class.only_if('90% ne 100%', {})).to be true
      end
    end

    context 'with !=' do
      it 'compares integers' do
        expect(described_class.only_if('1 != 1', {})).to be false
        expect(described_class.only_if('1 != 0', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 != 1.0', {})).to be false
        expect(described_class.only_if('1.0 != 0.1', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% != 90%', {})).to be false
        expect(described_class.only_if('90% != 100%', {})).to be true
      end

      it 'compares strings' do
        expect(described_class.only_if("'foo' != 'foo'", {})).to be false
        expect(described_class.only_if("'foo' != 'bar'", {})).to be true
        expect(described_class.only_if("'foo' != 'FOO'", {})).to be true
        expect(described_class.only_if("'foo' != 'BAR'", {})).to be true
        expect(described_class.only_if("'this is a string' != 'this is a string'", {})).to be false
        expect(described_class.only_if("'this is a string' != 'THIS IS A STRING'", {})).to be true
        expect(described_class.only_if("'this is a string' != 'this is a test'", {})).to be true
        expect(described_class.only_if("'this is a string' != 'THIS IS A TEST'", {})).to be true
      end
    end

    context 'with lt' do
      it 'compares integers' do
        expect(described_class.only_if('1 lt 1', {})).to be false
        expect(described_class.only_if('1 lt 0', {})).to be false
        expect(described_class.only_if('0 lt 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 lt 1.0', {})).to be false
        expect(described_class.only_if('1.0 lt 0.1', {})).to be false
        expect(described_class.only_if('0.1 lt 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% lt 90%', {})).to be false
        expect(described_class.only_if('90% lt 100%', {})).to be true
      end
    end

    context 'with <' do
      it 'compares integers' do
        expect(described_class.only_if('1 < 1', {})).to be false
        expect(described_class.only_if('1 < 0', {})).to be false
        expect(described_class.only_if('0 < 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 < 1.0', {})).to be false
        expect(described_class.only_if('1.0 < 0.1', {})).to be false
        expect(described_class.only_if('0.1 < 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% < 90%', {})).to be false
        expect(described_class.only_if('90% < 100%', {})).to be true
      end
    end

    context 'with gt' do
      it 'compares integers' do
        expect(described_class.only_if('1 gt 1', {})).to be false
        expect(described_class.only_if('1 gt 0', {})).to be true
        expect(described_class.only_if('0 gt 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 gt 1.0', {})).to be false
        expect(described_class.only_if('1.0 gt 0.1', {})).to be true
        expect(described_class.only_if('0.1 gt 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% gt 90%', {})).to be false
        expect(described_class.only_if('90% gt 100%', {})).to be false
        expect(described_class.only_if('100% gt 90%', {})).to be true
      end
    end

    context 'with >' do
      it 'compares integers' do
        expect(described_class.only_if('1 > 1', {})).to be false
        expect(described_class.only_if('1 > 0', {})).to be true
        expect(described_class.only_if('0 > 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 > 1.0', {})).to be false
        expect(described_class.only_if('1.0 > 0.1', {})).to be true
        expect(described_class.only_if('0.1 > 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% > 90%', {})).to be false
        expect(described_class.only_if('90% > 100%', {})).to be false
        expect(described_class.only_if('100% > 90%', {})).to be true
      end
    end

    context 'with le' do
      it 'compares integers' do
        expect(described_class.only_if('1 le 1', {})).to be true
        expect(described_class.only_if('1 le 0', {})).to be false
        expect(described_class.only_if('0 le 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 le 1.0', {})).to be true
        expect(described_class.only_if('1.0 le 0.1', {})).to be false
        expect(described_class.only_if('0.1 le 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% le 90%', {})).to be true
        expect(described_class.only_if('90% le 100%', {})).to be true
        expect(described_class.only_if('100% le 90%', {})).to be false
      end
    end

    context 'with <=' do
      it 'compares integers' do
        expect(described_class.only_if('1 <= 1', {})).to be true
        expect(described_class.only_if('1 <= 0', {})).to be false
        expect(described_class.only_if('0 <= 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 <= 1.0', {})).to be true
        expect(described_class.only_if('1.0 <= 0.1', {})).to be false
        expect(described_class.only_if('0.1 <= 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% <= 90%', {})).to be true
        expect(described_class.only_if('90% <= 100%', {})).to be true
        expect(described_class.only_if('100% <= 90%', {})).to be false
      end
    end

    context 'with ge' do
      it 'compares integers' do
        expect(described_class.only_if('1 ge 1', {})).to be true
        expect(described_class.only_if('1 ge 0', {})).to be true
        expect(described_class.only_if('0 ge 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 ge 1.0', {})).to be true
        expect(described_class.only_if('1.0 ge 0.1', {})).to be true
        expect(described_class.only_if('0.1 ge 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% ge 90%', {})).to be true
        expect(described_class.only_if('90% ge 100%', {})).to be false
        expect(described_class.only_if('100% ge 90%', {})).to be true
      end
    end

    context 'with >=' do
      it 'compares integers' do
        expect(described_class.only_if('1 >= 1', {})).to be true
        expect(described_class.only_if('1 >= 0', {})).to be true
        expect(described_class.only_if('0 >= 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.only_if('1.0 >= 1.0', {})).to be true
        expect(described_class.only_if('1.0 >= 0.1', {})).to be true
        expect(described_class.only_if('0.1 >= 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.only_if('90% >= 90%', {})).to be true
        expect(described_class.only_if('90% >= 100%', {})).to be false
        expect(described_class.only_if('100% >= 90%', {})).to be true
      end
    end

    context 'interpolating variables' do
      let :vars do
        { integer: 42,
          float: 1.0,
          percentage: '90%',
          string1: 'this is a string',
          string2: 'this is a string with a % symbol' }
      end

      it 'compares an integer variable' do
        expect(described_class.only_if('42 eq %{integer}', vars)).to be true
        expect(described_class.only_if('1 eq %{integer}', vars)).to be false
      end

      it 'compares a float variable' do
        expect(described_class.only_if('1.0 eq %{float}', vars)).to be true
        expect(described_class.only_if('0.1 eq %{float}', vars)).to be false
      end

      it 'compares a percentage variable' do
        expect(described_class.only_if('90% eq %{percentage}', vars)).to be true
        expect(described_class.only_if('100% eq %{percentage}', vars)).to be false
      end

      it 'compares a string variable' do
        expect(described_class.only_if("'this is a string' == '%{string1}'", vars)).to be true
        expect(described_class.only_if("'this is a test' == '%{string1}'", vars)).to be false
      end

      it 'compares a string variable with a % symbol' do
        expect(described_class.only_if("'this is a string with a % symbol' == '%{string2}'",
                                       vars)).to be true
        expect(described_class.only_if("'this is a test with a % symbol' == '%{string2}'",
                                       vars)).to be false
      end
    end

    context 'with an invalid comparison' do
      it 'raises an exception' do
        expect{ described_class.only_if("'foo' == 42", {}) }.to \
          raise_exception Cyclid::API::Job::EvalException
      end
    end

    context 'with an unknown operator' do
      it 'raises an exception' do
        expect{ described_class.only_if('1 ~= 1', {}) }.to \
          raise_exception Cyclid::API::Job::EvalException
      end
    end
  end

  describe '.not_if' do
    context 'with eq' do
      it 'compares integers' do
        expect(described_class.not_if('1 eq 1', {})).to be false
        expect(described_class.not_if('1 eq 0', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 eq 1.0', {})).to be false
        expect(described_class.not_if('1.0 eq 0.1', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% eq 90%', {})).to be false
        expect(described_class.not_if('90% eq 100%', {})).to be true
      end
    end

    context 'with ==' do
      it 'compares integers' do
        expect(described_class.not_if('1 == 1', {})).to be false
        expect(described_class.not_if('1 == 0', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 == 1.0', {})).to be false
        expect(described_class.not_if('1.0 == 0.1', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% == 90%', {})).to be false
        expect(described_class.not_if('90% == 100%', {})).to be true
      end

      it 'compares strings' do
        expect(described_class.not_if("'foo' == 'foo'", {})).to be false
        expect(described_class.not_if("'foo' == 'bar'", {})).to be true
        expect(described_class.not_if("'foo' == 'FOO'", {})).to be false
        expect(described_class.not_if("'foo' == 'BAR'", {})).to be true
        expect(described_class.not_if("'this is a string' == 'this is a string'", {})).to be false
        expect(described_class.not_if("'this is a string' == 'THIS IS A STRING'", {})).to be false
        expect(described_class.not_if("'this is a string' == 'this is a test'", {})).to be true
        expect(described_class.not_if("'this is a string' == 'THIS IS A TEST'", {})).to be true
      end

      it 'compares empty strings' do
        expect(described_class.not_if("'' == ''", {})).to be false
        expect(described_class.not_if("'foo' == ''", {})).to be true
        expect(described_class.not_if("'' == 'foo'", {})).to be true
      end
    end

    context 'with ===' do
      it 'compares strings' do
        expect(described_class.not_if("'foo' === 'foo'", {})).to be false
        expect(described_class.not_if("'foo' === 'bar'", {})).to be true
        expect(described_class.not_if("'foo' === 'FOO'", {})).to be true
        expect(described_class.not_if("'foo' === 'BAR'", {})).to be true
        expect(described_class.not_if("'this is a string' === 'this is a string'", {})).to be false
        expect(described_class.not_if("'this is a string' === 'THIS IS A STRING'", {})).to be true
        expect(described_class.not_if("'this is a string' === 'this is a test'", {})).to be true
        expect(described_class.not_if("'this is a string' === 'THIS IS A TEST'", {})).to be true
      end

      it 'compares empty strings' do
        expect(described_class.not_if("'' === ''", {})).to be false
        expect(described_class.not_if("'foo' === ''", {})).to be true
        expect(described_class.not_if("'' === 'foo'", {})).to be true
      end
    end

    context 'with ne' do
      it 'compares integers' do
        expect(described_class.not_if('1 ne 1', {})).to be true
        expect(described_class.not_if('1 ne 0', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 ne 1.0', {})).to be true
        expect(described_class.not_if('1.0 ne 0.1', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% ne 90%', {})).to be true
        expect(described_class.not_if('90% ne 100%', {})).to be false
      end
    end

    context 'with !=' do
      it 'compares integers' do
        expect(described_class.not_if('1 != 1', {})).to be true
        expect(described_class.not_if('1 != 0', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 != 1.0', {})).to be true
        expect(described_class.not_if('1.0 != 0.1', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% != 90%', {})).to be true
        expect(described_class.not_if('90% != 100%', {})).to be false
      end

      it 'compares strings' do
        expect(described_class.not_if("'foo' != 'foo'", {})).to be true
        expect(described_class.not_if("'foo' != 'bar'", {})).to be false
        expect(described_class.not_if("'foo' != 'FOO'", {})).to be false
        expect(described_class.not_if("'foo' != 'BAR'", {})).to be false
        expect(described_class.not_if("'this is a string' != 'this is a string'", {})).to be true
        expect(described_class.not_if("'this is a string' != 'THIS IS A STRING'", {})).to be false
        expect(described_class.not_if("'this is a string' != 'this is a test'", {})).to be false
        expect(described_class.not_if("'this is a string' != 'THIS IS A TEST'", {})).to be false
      end
    end

    context 'with lt' do
      it 'compares integers' do
        expect(described_class.not_if('1 lt 1', {})).to be true
        expect(described_class.not_if('1 lt 0', {})).to be true
        expect(described_class.not_if('0 lt 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 lt 1.0', {})).to be true
        expect(described_class.not_if('1.0 lt 0.1', {})).to be true
        expect(described_class.not_if('0.1 lt 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% lt 90%', {})).to be true
        expect(described_class.not_if('90% lt 100%', {})).to be false
      end
    end

    context 'with <' do
      it 'compares integers' do
        expect(described_class.not_if('1 < 1', {})).to be true
        expect(described_class.not_if('1 < 0', {})).to be true
        expect(described_class.not_if('0 < 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 < 1.0', {})).to be true
        expect(described_class.not_if('1.0 < 0.1', {})).to be true
        expect(described_class.not_if('0.1 < 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% < 90%', {})).to be true
        expect(described_class.not_if('90% < 100%', {})).to be false
      end
    end

    context 'with gt' do
      it 'compares integers' do
        expect(described_class.not_if('1 gt 1', {})).to be true
        expect(described_class.not_if('1 gt 0', {})).to be false
        expect(described_class.not_if('0 gt 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 gt 1.0', {})).to be true
        expect(described_class.not_if('1.0 gt 0.1', {})).to be false
        expect(described_class.not_if('0.1 gt 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% gt 90%', {})).to be true
        expect(described_class.not_if('90% gt 100%', {})).to be true
        expect(described_class.not_if('100% gt 90%', {})).to be false
      end
    end

    context 'with >' do
      it 'compares integers' do
        expect(described_class.not_if('1 > 1', {})).to be true
        expect(described_class.not_if('1 > 0', {})).to be false
        expect(described_class.not_if('0 > 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 > 1.0', {})).to be true
        expect(described_class.not_if('1.0 > 0.1', {})).to be false
        expect(described_class.not_if('0.1 > 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% > 90%', {})).to be true
        expect(described_class.not_if('90% > 100%', {})).to be true
        expect(described_class.not_if('100% > 90%', {})).to be false
      end
    end

    context 'with le' do
      it 'compares integers' do
        expect(described_class.not_if('1 le 1', {})).to be false
        expect(described_class.not_if('1 le 0', {})).to be true
        expect(described_class.not_if('0 le 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 le 1.0', {})).to be false
        expect(described_class.not_if('1.0 le 0.1', {})).to be true
        expect(described_class.not_if('0.1 le 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% le 90%', {})).to be false
        expect(described_class.not_if('90% le 100%', {})).to be false
        expect(described_class.not_if('100% le 90%', {})).to be true
      end
    end

    context 'with <=' do
      it 'compares integers' do
        expect(described_class.not_if('1 <= 1', {})).to be false
        expect(described_class.not_if('1 <= 0', {})).to be true
        expect(described_class.not_if('0 <= 1', {})).to be false
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 <= 1.0', {})).to be false
        expect(described_class.not_if('1.0 <= 0.1', {})).to be true
        expect(described_class.not_if('0.1 <= 1.0', {})).to be false
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% <= 90%', {})).to be false
        expect(described_class.not_if('90% <= 100%', {})).to be false
        expect(described_class.not_if('100% <= 90%', {})).to be true
      end
    end

    context 'with ge' do
      it 'compares integers' do
        expect(described_class.not_if('1 ge 1', {})).to be false
        expect(described_class.not_if('1 ge 0', {})).to be false
        expect(described_class.not_if('0 ge 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 ge 1.0', {})).to be false
        expect(described_class.not_if('1.0 ge 0.1', {})).to be false
        expect(described_class.not_if('0.1 ge 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% ge 90%', {})).to be false
        expect(described_class.not_if('90% ge 100%', {})).to be true
        expect(described_class.not_if('100% ge 90%', {})).to be false
      end
    end

    context 'with >=' do
      it 'compares integers' do
        expect(described_class.not_if('1 >= 1', {})).to be false
        expect(described_class.not_if('1 >= 0', {})).to be false
        expect(described_class.not_if('0 >= 1', {})).to be true
      end

      it 'compares floats' do
        expect(described_class.not_if('1.0 >= 1.0', {})).to be false
        expect(described_class.not_if('1.0 >= 0.1', {})).to be false
        expect(described_class.not_if('0.1 >= 1.0', {})).to be true
      end

      it 'compares percentages' do
        expect(described_class.not_if('90% >= 90%', {})).to be false
        expect(described_class.not_if('90% >= 100%', {})).to be true
        expect(described_class.not_if('100% >= 90%', {})).to be false
      end
    end

    context 'interpolating variables' do
      let :vars do
        { integer: 42,
          float: 1.0,
          percentage: '90%',
          string1: 'this is a string',
          string2: 'this is a string with a % symbol' }
      end

      it 'compares an integer variable' do
        expect(described_class.not_if('42 eq %{integer}', vars)).to be false
        expect(described_class.not_if('1 eq %{integer}', vars)).to be true
      end

      it 'compares a float variable' do
        expect(described_class.not_if('1.0 eq %{float}', vars)).to be false
        expect(described_class.not_if('0.1 eq %{float}', vars)).to be true
      end

      it 'compares a percentage variable' do
        expect(described_class.not_if('90% eq %{percentage}', vars)).to be false
        expect(described_class.not_if('100% eq %{percentage}', vars)).to be true
      end

      it 'compares a string variable' do
        expect(described_class.not_if("'this is a string' == '%{string1}'", vars)).to be false
        expect(described_class.not_if("'this is a test' == '%{string1}'", vars)).to be true
      end

      it 'compares a string variable with a % symbol' do
        expect(described_class.not_if("'this is a string with a % symbol' == '%{string2}'",
                                      vars)).to be false
        expect(described_class.not_if("'this is a test with a % symbol' == '%{string2}'",
                                      vars)).to be true
      end
    end

    context 'with an invalid comparison' do
      it 'raises an exception' do
        expect{ described_class.not_if("'foo' == 42", {}) }.to \
          raise_exception Cyclid::API::Job::EvalException
      end
    end

    context 'with an unknown operator' do
      it 'raises an exception' do
        expect{ described_class.not_if('1 ~= 1', {}) }.to \
          raise_exception Cyclid::API::Job::EvalException
      end
    end
  end
end
