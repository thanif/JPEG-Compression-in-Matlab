
% Quantization Matrix for Y Channel
Y_Q = [16 11 10 16 24 15 1 61;12 12 14 19 26 58 60 55;14 13 16 24 40 57 69 56;14 17 22 29 51 81 80 62;18 22 37 56 68 109 103 77;24 35 55 64 81 104 113 92;49 64 78 87 103 121 120 101;72 92 95 98 112 100 103 99];

% Quantization Matrix for Cb and Cr Channel
Cb_Cr_Q = [17 18 24 47 99 99 99 99;18 21 26 66 99 99 99 99;24 26 56 99 99 99 99 99;47 66 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99];

% Indices for Run Length Encoding
RLE_i = [1 2 9 17 10 3 4 11;18 25 33 26 19 12 5 6;13 20 27 34 41 49 42 35;28 21 14 7 8 15 22 29;36 43 50 57 58 51 44 37;30 23 16 24 31 38 45 52;59 60 53 46 39 32 40 47;54 61 62 55 48 56 63 64];

im = imread('imgs/lena512.bmp');

if ndims(im)==2
   
    im2(:,:,1) = im(:,:);
    im2(:,:,2) = im(:,:);
    im2(:,:,3) = im(:,:);
    
else
    
    im2 = im;
    
end

[r,c,ch] = size(im2);

% Store Decompressed Image
dc_im = zeros(r,c,ch);


% Convert RGB to YCbCr
ycbcr = rgb2ycbcr(im2);

% Mapping to the range [-128,127]
ycbcr = ycbcr - 128;

ycbcr = double(ycbcr);


    

    
for z = 1:3
    
    imSz = size(ycbcr);
    patchSz = [8 8];
    xIdxs = [1:patchSz(2):imSz(2) imSz(2)+1];
    yIdxs = [1:patchSz(1):imSz(1) imSz(1)+1];
    patches = cell(length(yIdxs)-1,length(xIdxs)-1);

    for i = 1:length(yIdxs)-1
        Isub = ycbcr(yIdxs(i):yIdxs(i+1)-1,:,z);
        sub = dc_im(yIdxs(i):yIdxs(i+1)-1,:,z);
        
        for j = 1:length(xIdxs)-1
            patches{i,j} = Isub(:,xIdxs(j):xIdxs(j+1)-1);
            
            % Apply DCT
            t_patch = dct(patches{i,j});
            % Apply Quantization  
            if z == 1
                
                q_patch = t_patch./Y_Q;
                        
            else
                        
                q_patch = t_patch./Cb_Cr_Q;
            end
               
            
            if sum(sum(q_patch)) > 0
            
                % Save quantized output in zigzag format
                
                rle = q_patch(RLE_i);
                        
                % Finding unique elements
                symbols = unique(rle);
                % Finding count of each element
                count = zeros(1,length(symbols));
                
                for k = 1:length(symbols)
                    
                    count(k) = sum(sum(rle==symbols(k)));
                    
                end
        
                % Finding probability of each element
                prob = zeros(1,length(symbols));
                
                for k = 1:length(symbols)
           
                    prob(k) = count(k)/64;
            
                end
        
                % Create Huffman Code dictionary
                dict = huffmandict(symbols,prob);
        
                % Apply Huffman Encoding
                hcode = huffmanenco(rle(:),dict);
            
            else
                
                hcode = 0;
                
            end
            
            if length(hcode) > 1
            
                % Apply Huffman Decoding
                
                t_patch = huffmandeco(hcode,dict);
                
                % Convert patch from zigzag to original format
                p = 1;
           
                q_patch = zeros(8,8);
            
                for k = 1:8
                
                    for l = 1:8
                
                        q_patch(k,l) = t_patch(RLE_i==p);
                    
                        p = p+1;
                    
                    end
                
                end
            
                % Apply Inverse Quantization
                
                if z == 1
                
                    iq_patch = q_patch.*Y_Q;
                        
                else
                        
                    iq_patch = q_patch.*Cb_Cr_Q;
                      
                    
                end
            
            
                % Apply Inverse DCT
                patch = idct(iq_patch); 
                
            else
                
                patch = zeros(8,8);
                
            end
            
            sub(:,xIdxs(j):xIdxs(j+1)-1) = patch;
            dc_im(yIdxs(i):yIdxs(i+1)-1,:,z) = sub;
            
        end
    end
end

dc_im = uint8(dc_im);

dc_im = dc_im + 128;

dc_im_rgb = ycbcr2rgb(dc_im);


imshow(dc_im_rgb)