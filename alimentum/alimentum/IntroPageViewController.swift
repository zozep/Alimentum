//
//  AppDelegate.swift
//  alimentum
//
//  Created by Joseph Park, Nitish Dayal
//  Copyright © 2016 Joseph Park, Nitish Dayal. All rights reserved.


import UIKit
import CoreLocation
import OAuthSwift


//MARK: - Declare protocol 'IntroPageViewControllerDelegate'

protocol IntroPageViewControllerDelegate: class {
    
    /* Function that will be called to update current page count */
    func introPageViewController(_ pageViewController: IntroPageViewController, didUpdatePageCount count: Int)
    
    func introPageViewController(_ pageViewController: IntroPageViewController, didUpdatePageIndex index: Int)
}


class IntroPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
   
//MARK: - Declare variables to be used throughout IntroPageViewController
    weak var viewDelegate : IntroPageViewControllerDelegate?
    lazy var orderedViewControllers: [UIViewController] = {
        
        //When orderedViewControllers is called upon, set to array of value returned from calling method(function) newViewController
        return [self.newViewController("page1"),
                self.newViewController("page2"),
                self.newViewController("page3")]
    }()
    
    
//MARK: - Declare default functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //On view load, set self to be dataSource and delegate for PageViewController
        dataSource = self
        delegate = self
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if launchedBefore {
            let mainAppStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = mainAppStoryboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
            
            //Present is done asynchronously in order to allow for current view controller to be added to the view hierarchy. Otherwise app breaks
            mainVC.checkLocationServices()

            DispatchQueue.main.async {
                self.present(mainVC, animated: true, completion: nil)

            }
            
        //If launchedBefore returns false/is not set, set value for launchedBefore to true and show introductory views
        } else {
            UserDefaults.standard.set(true, forKey: "launchedBefore")

            if let firstViewController = orderedViewControllers.first {
                setViewControllers([firstViewController],direction: .forward, animated: true, completion: nil)
                viewDelegate?.introPageViewController(self, didUpdatePageCount: orderedViewControllers.count)
            }
            initAppearance()
        }
    
    }
    
    
//MARK: - UIPageViewControllerDelegate/DataSource functions
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool){
        
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.index(of: firstViewController) {
                viewDelegate?.introPageViewController(self, didUpdatePageIndex: index)
            }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {return nil}
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {return nil}
        guard orderedViewControllers.count > previousIndex else {return nil}
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {return nil}
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else {return nil}
        guard orderedViewControllersCount > nextIndex else {return nil}
        
        return orderedViewControllers[nextIndex]
    }
    
    
//MARK:  - Custom functions
    
    /* Takes a parameter "identifier" of type string */
    func newViewController(_ identifier: String) -> UIViewController {
        
        //Returns view controller that matches identifier passed in as parameter
        return UIStoryboard(name: "FirstTime", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    func initAppearance() -> Void {
        let background = CAGradientLayer().turquoiseColor()
        background.frame = self.view.bounds
        self.view.layer.insertSublayer(background, at: 0)
    }

}





