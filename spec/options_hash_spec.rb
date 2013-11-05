require 'spec_helper'

describe OptionsHash do
  subject{ described_class }

  it { should_not respond_to :new           }
  it { should_not respond_to :options       }
  it { should_not respond_to :keys          }
  it { should_not respond_to :required_keys }
  it { should_not respond_to :optional_keys }
  it { should_not respond_to :required      }
  it { should_not respond_to :optional      }

  its(:name   ){ should == 'OptionsHash' }
  its(:inspect){ should == 'OptionsHash' }
  its(:to_s   ){ should == 'OptionsHash' }

  shared_examples 'an options hash' do
    it { should_not respond_to :new       }
    it { should respond_to :options       }
    it { should respond_to :keys          }
    it { should respond_to :required_keys }
    it { should respond_to :optional_keys }
    it { should respond_to :required      }
    it { should respond_to :optional      }
  end

  shared_examples 'an options hash instance' do
    its(:inspect){ should =~ %r[#<#{subject.class.class_name} #{subject.to_hash.inspect}>] }
    its(:to_s   ){ should =~ %r[#<#{subject.class.class_name} #{subject.to_hash.inspect}>] }
    it 'should respond to each key' do
      subject.keys.each do |key|
        expect(subject).to respond_to "#{key}"
        expect(subject).to respond_to "#{key}?"
      end
    end
  end


  describe '.parse' do
    context 'when given no arguments' do
      subject{ ->{ OptionsHash.parse } }
      it { should raise_error ArgumentError, 'wrong number of arguments (0 for 1)' }
    end

    context 'when given no block' do
      subject{ ->{ OptionsHash.parse({}) } }
      it { should raise_error ArgumentError, 'block required' }
    end

    context 'when given insufficient options' do
      subject{ ->{ OptionsHash.parse({}){ required :name } } }
      it { should raise_error ArgumentError, 'required options: :name' }
    end

    context 'when given unknown options' do
      subject{ ->{ OptionsHash.parse(foo:1){ } } }
      it { should raise_error ArgumentError, 'unknown options: :foo' }
    end

    context 'when given valid options' do
      subject do
        OptionsHash.parse(name: 'steve') do
          required :name
          optional :size, default: 42
        end
      end
      it_behaves_like 'an options hash instance'
      its(:name){ should eq 'steve' }
      its(:size){ should eq 42 }
      its(:to_hash){ should eq(:name=>"steve", :size=>42) }
    end
  end


  describe 'OptionsHash(required: [:a, :b], optional: [:c, :d])' do
    let :options_hash do
      Class.new(OptionsHash) do
        required :a
        required :b do |b|
          b.inspect
        end
        optional :c
        optional :d, default: ->{ 42 }
      end
    end
    describe '.parse' do
      context '(nil)' do
        subject{ ->{ options_hash.parse(nil) } }
        it{ should raise_error ArgumentError, 'required options: :a, :b' }
      end
      context '({})' do
        subject{ ->{ options_hash.parse({}) } }
        it{ should raise_error ArgumentError, 'required options: :a, :b' }
      end
      context '(a:1)' do
        subject{ ->{ options_hash.parse(a:1) } }
        it{ should raise_error ArgumentError, 'required options: :b' }
      end
      context '(b:1)' do
        subject{ ->{ options_hash.parse(b:1) } }
        it{ should raise_error ArgumentError, 'required options: :a' }
      end
      context '(a:1, b:2)' do
        subject{ options_hash.parse(a:1, b:2) }
        its(:a){ should eq 1 }
        its(:b){ should eq '2' }
        its(:c){ should be_nil }
        its(:d){ should eq 42 }
      end
      context '(a:1, b:2, c:3)' do
        subject{ options_hash.parse(a:1, b:2, c:3) }
        its(:a){ should eq 1 }
        its(:b){ should eq '2' }
        its(:c){ should eq 3 }
        its(:d){ should eq 42 }
      end
      context '(a:1, b:2, c:3, d:4)' do
        subject{ options_hash.parse(a:1, b:2, c:3, d:4) }
        its(:a){ should eq 1 }
        its(:b){ should eq '2' }
        its(:c){ should eq 3 }
        its(:d){ should eq 4 }
      end
      context '(a: nil, b: nil, c: nil, d: nil)' do
        subject{ options_hash.parse(a: nil, b: nil, c: nil, d: nil) }
        its(:a){ should be_nil }
        its(:b){ should eq 'nil' }
        its(:c){ should be_nil }
        its(:d){ should be_nil }
      end
    end

    describe '#define_attr_readers' do
      it 'should freeze the options hash' do
        expect(options_hash).to_not be_frozen
        options_hash.define_attr_readers(Class.new)
        expect(options_hash).to be_frozen
      end
      it "should define attr readers for each option" do
        options_hash = self.options_hash
        _class = Class.new
        _class.send(:define_method, :initialize) do |options|
          @options = options_hash.parse(options)
        end
        options_hash.define_attr_readers(_class)

        expect(_class.new(a:1,b:2,c:3,d:4).a).to eq 1
        expect(_class.new(a:1,b:2,c:3,d:4).b).to eq '2'
        expect(_class.new(a:1,b:2,c:3,d:4).c).to eq 3
        expect(_class.new(a:1,b:2,c:3,d:4).d).to eq 4


        options_hash = self.options_hash
        _class = Class.new
        _class.send(:define_method, :initialize) do |options|
          @swordfish = options_hash.parse(options)
        end
        options_hash.define_attr_readers(_class, :@swordfish)

        expect(_class.new(a:1,b:2,c:3,d:4).a).to eq 1
        expect(_class.new(a:1,b:2,c:3,d:4).b).to eq '2'
        expect(_class.new(a:1,b:2,c:3,d:4).c).to eq 3
        expect(_class.new(a:1,b:2,c:3,d:4).d).to eq 4
      end
    end
  end


  describe 'Class.new(OptionsHash)' do
    subject{ Class.new(OptionsHash) }

    it_behaves_like 'an options hash'

    its(:name   ){ should be_nil }
    its(:inspect){ should =~ %r{OptionsHash:(\w+)\(required: \[\], optional: \[\]\)} }
    its(:to_s   ){ should =~ %r{OptionsHash:(\w+)\(required: \[\], optional: \[\]\)} }

    describe '.parse({})' do
      subject{ Class.new(OptionsHash).parse({}) }
      it_behaves_like 'an options hash instance'
    end
    describe '.parse(nil)' do
      subject{ Class.new(OptionsHash).parse(nil) }
      it_behaves_like 'an options hash instance'
    end
  end



  describe EmptyOptions do
    subject{ EmptyOptions }

    it_behaves_like 'an options hash'

    its(:name   ){ should == 'EmptyOptions' }
    its(:inspect){ should == %{EmptyOptions(required: [], optional: [])} }
    its(:to_s   ){ should == %{EmptyOptions(required: [], optional: [])} }
  end

  describe PersonOptions do
    subject{ PersonOptions }

    it_behaves_like 'an options hash'

    its(:keys){ should eq Set[:name, :level_of_schooling, :height, :weight, :size, :iq, :intelegence] }

    describe %(PersonOptions.parse(name: 'jared', level_of_schooling: 100, iq: 240, intelegence: 2)) do
      subject{ PersonOptions.parse(name: 'jared', level_of_schooling: 100, iq: 240, intelegence: 2) }

      it_behaves_like 'an options hash instance'

      its(:name?               ){ should be_true   }
      its(:level_of_schooling? ){ should be_true   }
      its(:height?             ){ should be_false  }
      its(:weight?             ){ should be_false  }
      its(:size?               ){ should be_false  }
      its(:iq?                 ){ should be_true   }
      its(:intelegence?        ){ should be_true   }
      its(:name                ){ should eq 'jared'}
      its(:level_of_schooling  ){ should eq 100    }
      its(:height              ){ should eq 2      }
      its(:weight              ){ should eq 2      }
      its(:size                ){ should eq 400    }
      its(:iq                  ){ should eq 120.0  }
      its(:intelegence         ){ should eq 1.0    }

      its(:keys){ should eq Set[:name, :level_of_schooling, :height, :weight, :size, :iq, :intelegence] }
      its(:to_hash){ should eq(:name=>"jared", :level_of_schooling=>100, :height=>2, :weight=>2, :size=>400, :iq=>120.0, :intelegence=>1.0) }
    end

    describe 'argument errors' do
      it "should be raised" do
        expect{ subject.parse                                                        }.to raise_error ArgumentError, 'wrong number of arguments (0 for 1)'
        expect{ subject.parse({})                                                    }.to raise_error ArgumentError, 'required options: :intelegence, :iq, :level_of_schooling, :name'
        expect{ subject.parse(intelegence: 1)                                        }.to raise_error ArgumentError, 'required options: :iq, :level_of_schooling, :name'
        expect{ subject.parse(intelegence: 1, iq: 1)                                 }.to raise_error ArgumentError, 'required options: :level_of_schooling, :name'
        expect{ subject.parse(intelegence: 1, iq: 1, level_of_schooling: 1)          }.to raise_error ArgumentError, 'required options: :name'
        expect{ subject.parse(intelegence: 1, iq: 1, level_of_schooling: 1, name: 1) }.to_not raise_error
        expect{ subject.parse(b:1, a:2, name:'steve')                                }.to raise_error ArgumentError, 'unknown options: :a, :b'
      end
    end
  end

  describe 'Person.new' do
    let(:proc){ ->{ Person.new } }
    subject{ proc }
    it { should raise_error ArgumentError, 'required options: :intelegence, :iq, :level_of_schooling, :name' }

    describe 'ArgumentError' do
      let(:error){ begin; proc.call; rescue => error; error end }
      subject{ error }

      describe 'backtrace[0]' do
        subject{ error.backtrace[0] }
        it { should eq "#{Bundler.root+'spec/support/person.rb'}:6:in `initialize'" }
      end
    end
  end

  describe 'Person.new(father:1)' do
    let(:proc){ ->{ Person.new(father:1) } }
    subject{ proc }
    it { should raise_error ArgumentError, 'unknown options: :father' }

    describe 'ArgumentError' do
      let(:error){ begin; proc.call; rescue => error; error end }
      subject{ error }

      describe 'backtrace[0]' do
        subject{ error.backtrace[0] }
        it { should eq "#{Bundler.root+'spec/support/person.rb'}:6:in `initialize'" }
      end
    end
  end

  describe %[Person.new(name: 'jared', level_of_schooling: 100, iq: 240, intelegence: 2)] do
    subject{ Person.new(name: 'jared', level_of_schooling: 100, iq: 240, intelegence: 2) }
    it{ should respond_to :name               }
    it{ should respond_to :level_of_schooling }
    it{ should respond_to :height             }
    it{ should respond_to :weight             }
    it{ should respond_to :size               }
    it{ should respond_to :iq                 }
    it{ should respond_to :intelegence        }
    its(:name                ){ should eq 'jared'}
    its(:level_of_schooling  ){ should eq 100    }
    its(:height              ){ should eq 2      }
    its(:weight              ){ should eq 2      }
    its(:size                ){ should eq 400    }
    its(:iq                  ){ should eq 120.0  }
    its(:intelegence         ){ should eq 1.0    }
  end

end
