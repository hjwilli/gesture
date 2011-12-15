%==========================================================================
% RECOG_TEMPLATE Recognizer template object             
%==========================================================================
% a=recog_template(hyper) 
%
% This is an object similar to a Spider object
% http://www.kyb.mpg.de/bs/people/spider/
%
% All recognizers (called "model") must have at least 2 methods: rain and test
% [resu, model]=train(model, data)
% resu = test(model, data)

%Isabelle Guyon -- isabelle@clopinet.com -- October 2011

classdef recog_template
	properties (SetAccess = public)
        len=[];                 % Average length of a single gesture
        T={};                   % List of templates from training data
        movie_type='K';         % A choice of 'M' for the RGB image or 'K' for the depth image
        verbosity=0;            % Flag to turn on verbose mode for debug
        test_on_training_data=0;% Flag to turn on training data
    end
    methods
        %%%%%%%%%%%%%%%%%%%
        %%% CONSTRUCTOR %%%
        %%%%%%%%%%%%%%%%%%%
        function a = recog_template(hyper) 
            % Evaluate hyper-parameters entered with the syntax of the
            % Spider http://www.kyb.mpg.de/bs/people/spider/
            eval_hyper;
        end  
        
        function show(this, h)
            % Show the templates
            if nargin<2 || isempty(h)
                h=figure('name', 'recog_template', 'Position', [22 49 1194 634]);
            else
                figure(h);
                clf;
            end
            hold on
            N=length(this.T);
            dim=ceil(sqrt(N));
            dim1=dim;
            for k=1:dim
                dim2=k;
                if N<dim1*dim2;
                    break;
                end
            end
            hold off
            for j=1:N
                subplot(dim1,dim2, j);
                im=this.T{j};
                mini=min(im(:));
                maxi=max(im(:));
                im=(im-mini)/(maxi-mini);
                imagesc(im);
                axis off
                axis image
                title(num2str(j));
            end
        end
        
    end %methods
end %classdef
  

 

 
 





