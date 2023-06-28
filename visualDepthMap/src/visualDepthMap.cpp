#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>

#include <vector>
#include <conio.h>
#include <SpectralRadar.h>

#include <chrono>
#include <thread>

using namespace cv;
using namespace std;

#include <iostream>


void ExportDataAndImage(string n, double startX, double startY, double stopX, double stopY) {
	char message[1024];

	OCTDeviceHandle Dev = initDevice();
	ProbeHandle Probe = initProbe(Dev, "Probe_Standard_OCTG_LSM03.ini");
	//ProbeHandle Probe = initProbe(Dev, "Probe");
	ProcessingHandle Proc = createProcessingForDevice(Dev);

	RawDataHandle Raw = createRawData();
	DataHandle BScan = createData();
	ColoredDataHandle VideoImg = createColoredData();


	if (getError(message, 1024)) {
		cout << "ERROR: " << message << endl;
		(void)getchar();
		return;
	}


	getNumberOfDevicePresetCategories(Dev);

	// The scan speed of SD-OCT systems can be changed. A better image quality can be obtained with a longer integration time and therefore lower scan speed.
	// Preset 0 is the default scan speed followed by the highest. Please note to adjust the reference intensity on your scanner manually.
	// The number of available device presets can be obtained with #getNumberOfDevicePresets and the description of each preset with #getDevicePresetDescription
	int NumberOfDevicePresets = getNumberOfDevicePresets(Dev, 0);
	cout << getDevicePresetDescription(Dev, 0, 0) << endl;
	setDevicePreset(Dev, 0, Probe, Proc, 0);




	ScanPatternHandle Pattern = createBScanPatternManual(Probe, startX, startY, stopX, stopY, 1024);

	startMeasurement(Dev, Pattern, Acquisition_AsyncFinite);

	getRawData(Dev, Raw);
	setProcessedDataOutput(Proc, BScan);
	executeProcessing(Proc, Raw);

	stopMeasurement(Dev);


	ColoringHandle Coloring = createColoring32Bit(ColorScheme_BlackAndWhite, Coloring_RGBA);
	// set the boundaries for the colormap, 0.0 as lower and 70.0 as upper boundary are a good choice normally.
	setColoringBoundaries(Coloring, 0.0, 70.0);
	// Exports the processed data to an image with the specified slice normal direction since this will result in 2D-images.
	// To get the B-scan in one image with depth and scan field as axes for a single B-scan #Direction_3 is chosen.



	string filepath = "C:\\Ajay_OCT\\visualDepthMap\\data\\oct";
	string exten = ".jpg";
	string fullpath = filepath + n + exten;
	const char* cstr = fullpath.c_str();

	exportDataAsImage(BScan, Coloring, ColoredDataExport_JPG, Direction_3, cstr, ExportOption_DrawScaleBar | ExportOption_DrawMarkers | ExportOption_UsePhysicalAspectRatio);
	//cv::Mat OCTimage = cv::imread("C:/Ajay_OCT/visualDepthMap/data/oct.jpg", cv::IMREAD_COLOR);


	getCameraImage(Dev, VideoImg);
	
	
	unsigned long * data = getColoredDataPtr(VideoImg);
	//float* data = getDataPtr(VideoImg);
	int width = 648;
	int height = 484;

	visualizeScanPatternOnImage(Probe, Pattern, VideoImg);


	//std::this_thread::sleep_for(std::chrono::seconds(1));
	// Convert 
	cv::Mat videoImagecv = cv::Mat(height, width, CV_8UC3);
	for (int i = 0; i < height; i++) {
		for (int j = 0; j < width; j++) {
			unsigned long pixelValue = data[i * width + j];
			cv::Vec3b& pixel = videoImagecv.at<cv::Vec3b>(i, j);
			pixel[0] = (pixelValue >> 16) & 0xFF; // Blue channel
			pixel[1] = (pixelValue >> 8) & 0xFF;  // Green channel
			pixel[2] = pixelValue & 0xFF;         // Red channel
		}
	}
	

	filepath = "C:\\Ajay_OCT\\visualDepthMap\\data\\scanPattern";
	exten = ".jpg";
	fullpath = filepath + n + exten;
	cstr = fullpath.c_str();

	cv::imwrite(cstr, videoImagecv);


	// TODO: warum nicht .srm?



	clearScanPattern(Pattern);

	clearData(BScan);
	clearRawData(Raw);
	clearColoredData(VideoImg);

	clearProcessing(Proc);
	closeProbe(Probe);
	closeDevice(Dev);

	_getch();
}


int main(){

	double startX = -2.2;
	double startY = -1.0;
	double stopX = 2.7;
	double stopY = -1.0;

	ExportDataAndImage("1", startX, startY, stopX, stopY);

	std::cout << "1 done; 2 to start" << std::endl;
	startX = -2.2;
	startY = 0.0;
	stopX = 2.7;
	stopY = 0.0;
	
	ExportDataAndImage("2", startX, startY, stopX, stopY);


	std::cout << "2 done; 3 to start" << std::endl;
	startX = -2.2;
	startY = -2.0;
	stopX = 2.7;
	stopY = -2.0;

	ExportDataAndImage("3", startX, startY, stopX, stopY);



	return 0;

	std::cout<<"main done"<<std::endl;
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file






