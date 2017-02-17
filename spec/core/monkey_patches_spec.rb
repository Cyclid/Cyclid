# frozen_string_literal: true
require 'spec_helper'

describe String do
  describe '#**' do
    let :s do
      '%{foo}'
    end

    it 'interpolates a string' do
      expect(s ** { foo: 'test' }).to eq 'test'
    end

    it 'interpolates a string when the key is missing' do
      expect(s ** { bar: 'test' }).to eq ''
    end
  end
end

describe Hash do
  describe '#%' do
    let :h do
      { foo: '%{foo}', bar: 'bar', baz: 42 }
    end

    it 'interpolates a hash' do
      expect(h % { foo: 'test' }).to include(foo: 'test', bar: 'bar', baz: 42)
    end
  end
end

describe Array do
  describe '#%' do
    let :a do
      ['%{foo}', { bar: '%{bar}' }, 'baz', 42]
    end

    it 'interpolates an array' do
      expect(a % { foo: 'foo', bar: 'bar' }).to include('foo', { bar: 'bar' }, 'baz', 42)
    end
  end
end
