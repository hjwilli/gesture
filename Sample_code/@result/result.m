%=============================================================================
% result Data structure             
%=============================================================================  
% D=result(object)
% 
% Creates a result container given a databatch object or another result object.
% Warning: a result object is a handle. To make a physical copy of R0, use
% R=result(R0); not R=R0; or use R=subset(R0, idx);
% When the argument is a data object, both X and Y hold the truth values.
%
% For consistency with the Spider objects
% http://www.kyb.mpg.de/bs/people/spider/
% X holds the predictions and Y the truth values.

%==========================================================================
% Author of code: Isabelle Guyon -- isabelle@clopinet.com -- October 2011
%==========================================================================

classdef result < handle
	properties (SetAccess = public)
        subidx=[];
        invidx=[];
        Y={}; % Holds the truth values
        X={}; % Holds the results
    end
    methods
        %%%%%%%%%%%%%%%%%%%
        %%% CONSTRUCTOR %%%
        %%%%%%%%%%%%%%%%%%%
        function this = result(obj) 
            if nargin<1, return; end
            this.subidx=obj.subidx;
            this.invidx=obj.invidx;
            this.Y=obj.Y;
            if strmatch('X', properties(obj))
                this.X=obj.X;
            else
                this.X=cell(size(this.Y));
            end
        end          
        
        function D = subset(this, idx)
            %D = subset(this, idx)
            % Select a data subset
            D=result(this);
            D.subidx=idx;
            D.invidx(idx)=1:length(idx);
        end 
        
        function Y=get_Y(this, num)
            %Y=get_Y(this, num)
            if nargin<2
                Y=this.Y(this.subidx);
            else
                num=this.subidx(num);
                Y=this.Y{num};
            end
        end
        
        function X=get_X(this, num)
            %X=get_X(this, num)
            if isempty(this.X), return; end
            if nargin<2
                X=this.X(this.subidx);
            else
                num=this.subidx(num);
                if num>length(this.X), return; end
                X=this.X{num};
            end
        end
        
        function set_Y(this, num, val)
            %set_Y(this, num, val)
            num=this.subidx(num);
            this.Y{num}=val;
        end
        
        function set_X(this, num, val)
            %set_X(this, num, val)
            num=this.subidx(num);
            this.X{num}=val;
        end
        
        function n=length(this)
            %n=length(this)
            % number of samples
            n=length(this.subidx);
        end
        
        function n=labelnum(this)
            %n=labelnum(this)
            % number of labels (not of samples)
            Y=get_Y(this);
            n=0;
            for k=1:length(Y)
                n=n+length(Y{k});
            end
        end
            
        
        function [score, local_scores]=length_score(this)
            N=length(this);
            X=get_X(this);
            Y=get_Y(this);
            local_scores=zeros(N,1);
            n=0;
            for k=1:N
                true_length=length(Y{k});
                local_scores(k)=abs(length(X{k})-true_length);
                n=n+true_length;
            end
            score=sum(local_scores)/n;
        end
        
        function [score, local_scores]=leven_score(this)
            %lscore(this)
            [score, local_scores]=lscore(get_Y(this), get_X(this));
        end
        
        function save(this, filename, prefix, mode)
            %save(this)
            % Save the results in csv format
            if nargin<3, prefix=''; end
            if nargin<4, mode='w'; end
            samples=this.subidx;
            labels=this.X(samples);
            write_file(filename, samples, labels, prefix, mode);
        end
            
    end %methods
end % classdef
