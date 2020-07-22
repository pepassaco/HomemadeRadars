%% Pablo Álvarez Domínguez, EA4HFV
%  Radar Doppler por CW activo con RTL-SDR
%  v03 (2020-01-28)
%  Portadora a 1694MHz generada independientemente mediante un ADF4351

clear, clc
 
fport = 1693995313;                                                         % Frecuencia de la portadora
fcos = 7075;                                                                % Frecuencia para desmodulación
FrameLength = 8*4096;                                                       % Tamaño de la ventana
fs = 250e3;                                                                 % Frecuencia de muestreo
Ts = 1/fs;
t = (0:FrameLength-1)*Ts;                                                   % Vector de tiempos
numRep = 3000;                                                              % Número de iteraciones
fc1 = 2000;                                                                 % frecuencia de corte del primer filtro FIR
fc2 = fcos;                                                                 % frecuencia de corte del segundo filtro FIR
Mdiez = 32;                                                                 % Factor de diezmado
f = (0:FrameLength-1)*(fs/FrameLength);                                     % Vector frecuencias de 0 a fs 
y = zeros(FrameLength,1);                                                   % Señal correspondiente a la FFT de la entrada
c = cos(2*pi*fcos*t);                                                       % Señal desmoduladora
fshift = (-FrameLength/2:FrameLength/2-1)*(fs/FrameLength);                 % Vector frecuencias de -fs/2 a fs/2
fDiez = (0:FrameLength/Mdiez-1)*(fs/FrameLength);                           % Frecuencia tras diezmar
fDiezShift = (-FrameLength/(2*Mdiez):FrameLength/(2*Mdiez)-1)*(fs/FrameLength);



sdrrx = comm.SDRRTLReceiver('0','CenterFrequency',fport,'TunerGain',0,'SampleRate',fs, ...
    'SamplesPerFrame',FrameLength,'EnableTunerAGC',true,'OutputDataType','double');




figure


mx = zeros(1,numRep);                                                       % Variable donde se almacena la frecuencia Doppler final

m1 = double(f < fc1);                                                       % Forma de la respuesta
b1 = fir2(100,f/max(f),m1);                                                 % Filtro FIR
a1 = 1;
% hfvt = fvtool(b1,a1);
% pause


m2 = double(fDiez < fc2);                                                      % Forma de la respuesta
b2 = fir2(20,fDiez/max(fDiez),m2);                                                  % Filtro FIR
a2 = 1;
% hfvt = fvtool(b2,a2);
% pause


%% Procesado de la señal en tiempo real

if ~isempty(sdrinfo(sdrrx.RadioAddress))
    for count = 1 : numRep
        data = sdrrx();                                                     % Obtención de datos del SDR
        data = data - mean(data);                                           % Eliminación de la componente continua de la señal entrante
         
%         plot(t, real(data));
%         figure
%         plot(t, imag(data));
        
        dataDemod = data.*c';                                               % Desmodulación de la portadora
        
        dataFir = filter(b1,a1,dataDemod);                                  % Primer filtrado para eliminar espúreos y armónicos

        dataDiez = decimate(dataFir,Mdiez,5);                               % Diezmado de la señal para aumentar la resolución espectral y observar con mayor precisión la frecuencia doppler
        
        dataDiezFir = filter(b2,a2,dataDiez);                               % Segundo filtrado para eliminar la copia a alta frecuencias tras la desmodulación
        
        y5 = abs(fftshift(fft(dataDiezFir)));                               % DFT de la señal final
        
        
        
         y = abs(fftshift(fft(data)));
         y2 = abs(fftshift(fft(dataDemod)));
         y3 = abs(fftshift(fft(dataFir)));
%        y4 = abs(fftshift(fft(dataDiez)));
         plot(fshift, 20*log10(y), fshift, 20*log10(y2), fshift, 20*log10(y3));
%         axis([-fs/(2) fs/(2) -40 60]);
axis([-fs/(5*2) fs/(5*2) -40 60]);


%         plot(fshift, 20*log(y),fshift,20*log(y2),f,real(20*log(y3)));
%         axis([-fs/(2) fs/(2) 20 160]);
        


%         plot(fDiezShift,real(20*log(y5)));
%         axis([-fs/(2*Mdiez) fs/(2*Mdiez) -130 100]);
%       axis([-700 700 -40 60]);
        title('Magnitud de la FFT');
        xlabel('Frequency (Hz)');
        ylabel('magnitude');
        drawnow
        
        
%         [M,I] = max(y4);
%         if(count > 50)
%             I/FrameLength*fs/125
%         end
%         mx(1,count)=I/FrameLength*fs;
        
                
    end
    
%     a = 1:numRep;
%     figure
%     plot(a,mx);
else
    warning(message('sdrbase:sysobjdemos:MainLoop'))
end



% Release all System objects
release(sdrrx);